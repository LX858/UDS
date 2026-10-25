"""Integration tests of the actual Lua SQL plans against an isolated MariaDB database.

Dependencies: pymysql, lupa. Usage: python tools/test_invite_code.py --config /path/server.cfg
Never writes gameplay data: creates and drops only a unique tipi_invite_test_* database.
"""
import argparse
import concurrent.futures
import re
import uuid
from pathlib import Path
from urllib.parse import unquote, urlparse

import pymysql
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def connection_options(path):
    text = Path(path).read_text(encoding='utf-8-sig')
    match = re.search(r'''^\s*set\s+mysql_connection_string\s+["']([^"']+)''', text, re.M)
    if not match:
        raise RuntimeError('No mysql_connection_string in the supplied config')
    value = match[1]
    if '://' in value:
        url = urlparse(value)
        return dict(host=url.hostname or 'localhost', port=url.port or 3306,
                    user=unquote(url.username or 'root'), password=unquote(url.password or ''),
                    database=url.path.lstrip('/'), charset='utf8mb4')
    parts = dict(part.split('=', 1) for part in value.split(';') if '=' in part)
    return dict(host=parts.get('server', 'localhost'), port=int(parts.get('port', 3306)),
                user=parts.get('userid', parts.get('user', 'root')), password=parts.get('password', ''),
                database=parts['database'], charset='utf8mb4')


def run(config):
    options = connection_options(config)
    options.pop('database')
    admin = pymysql.connect(**options, autocommit=True)
    database = 'tipi_invite_test_' + uuid.uuid4().hex[:12]
    with admin.cursor() as cur:
        cur.execute(f'CREATE DATABASE `{database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
    options['database'] = database
    db = pymysql.connect(**options, autocommit=True, cursorclass=pymysql.cursors.DictCursor)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('Locales = {}; GetConvarInt = function(_, default) return default end')
    lua.execute((ROOT / 'config.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ROOT / 'server/classes/InviteCodeStore.lua').read_text(encoding='utf-8-sig'))
    store = lua.globals().InviteCodeStore
    assert lua.globals().Config.InviteCode.RequiredSeconds == 180000
    for path in [ROOT/'server/classes/InviteCodeStore.lua', ROOT/'server/impl/InviteCode.impl.lua',
                 ROOT/'client/impl/InviteCode.impl.lua', ROOT/'server/bridge.lua']:
        lua.execute('assert(load(...))', path.read_text(encoding='utf-8-sig'))

    def query(sql, args=(), conn=db):
        with conn.cursor() as cur:
            cur.execute(sql.replace('?', '%s'), tuple(args))
            return cur.fetchall() if cur.description else cur.rowcount

    def plans(q):
        return [(q[i]['query'], [q[i]['values'][j] for j in range(1, len(q[i]['values'])+1)])
                for i in range(1, len(q)+1)]

    def execute_plan(plan, conn=db):
        conn.begin()
        try:
            for sql, args in plan:
                query(sql, args, conn)
            conn.commit()
            return True
        except Exception:
            conn.rollback()
            raise

    def tx(q):
        return execute_plan(plans(q))

    def row(cid):
        return query('SELECT * FROM tipi_invite_redemptions WHERE invitee = ?', [cid])[0]

    def coin(cid):
        return query('SELECT coin FROM players WHERE citizenid = ?', [cid])[0]['coin']

    counter = 0

    def account(cid, license=None, tokens=None):
        nonlocal counter
        counter += 1
        query('INSERT IGNORE INTO players (citizenid, coin) VALUES (?, 0)', [cid])
        tx(store.identity(cid, f'TEST{counter:08d}', lua.table_from([license or cid]),
                          lua.table_from(tokens if tokens is not None else [cid+'a', cid+'b'])))

    def redeem(cid, owner, confirmed=False):
        tx(store.redeem(cid, owner, confirmed))

    def complete(cid, owner):
        query('UPDATE tipi_invite_redemptions SET online_seconds = 180000 WHERE invitee = ?', [cid])
        tx(store.award(cid, owner))

    passed = []

    def check(name):
        passed.append(name)
        print('PASS', name)

    try:
        query('CREATE TABLE players (citizenid VARCHAR(50) PRIMARY KEY, coin BIGINT NOT NULL DEFAULT 0, playtime BIGINT NOT NULL DEFAULT 0) ENGINE=InnoDB')
        migration = (ROOT/'tools/invite_code.sql').read_text(encoding='utf-8')
        for _ in range(2):
            for statement in migration.split(';'):
                if statement.strip(): query(statement)
        check('Lua syntax and additive migration rerun')

        account('owner'); account('a'); account('b')
        redeem('owner', 'owner')
        assert not query('SELECT * FROM tipi_invite_redemptions WHERE invitee = ?', ['owner'])
        redeem('a', 'owner'); redeem('a', 'b')
        assert row('a')['inviter'] == 'owner'
        check('Self redemption rejected; one-time relationship immutable')

        checkpoint = lua.table_from([lua.table_from(dict(cid='a', key=str(uuid.uuid4()), seconds=179999))])
        tx(store.checkpoint(checkpoint)); tx(store.checkpoint(checkpoint))
        tx(store.award('a', 'owner'))
        assert row('a')['online_seconds'] == 179999 and coin('a') == 0
        checkpoint[1]['seconds'] = 180000
        tx(store.checkpoint(checkpoint)); tx(store.award('a', 'owner')); tx(store.award('a', 'owner'))
        assert coin('a') == 50 and coin('owner') == 100 and row('a')['reward_slot'] == 1
        check('179999/180000 boundary, checkpoint retry and award retry')

        account('same-license', license='a')
        redeem('same-license', 'owner')
        account('same-tokens', tokens=['aa','ab']); redeem('same-tokens', 'owner')
        account('one-token', tokens=['aa','unique']); redeem('one-token', 'owner')
        assert not query('SELECT * FROM tipi_invite_redemptions WHERE invitee IN (?, ?)', ['same-license', 'same-tokens'])
        assert row('one-token')
        check('Duplicate license or two tokens rejected; one token allowed')

        account('missing', tokens=[]); redeem('missing', 'owner'); complete('missing', 'owner')
        assert row('missing')['qualified_at'] is None and coin('missing') == 0
        account('missing', tokens=['missing-a','missing-b']); tx(store.award('missing','owner'))
        assert coin('missing') == 50
        check('Missing identity waits; verified identity resumes')

        account('fraud-before'); redeem('fraud-before','owner')
        tx(store.fraud('fraud-before','console',True,'test')); complete('fraud-before','owner')
        assert row('fraud-before')['qualified_at'] is None and coin('fraud-before') == 0
        tx(store.fraud('fraud-before','console',False,'test clear')); tx(store.award('fraud-before','owner'))
        assert coin('fraud-before') == 50
        slot = row('fraud-before')['reward_slot']
        tx(store.fraud('fraud-before','console',True,'late fraud')); tx(store.award('fraud-before','owner'))
        assert coin('fraud-before') == 50 and row('fraud-before')['reward_slot'] == slot
        check('Fraud before payout blocks; late fraud preserves coins and consumed slot')

        account('cap-owner')
        for i in range(1, 50):
            cid=f'cap-{i}'; account(cid); redeem(cid,'cap-owner'); complete(cid,'cap-owner')
        assert coin('cap-owner') == 9750  # 49*100 + 250+600+1500+2500
        for cid in ['cap-50','cap-51']:
            account(cid); redeem(cid,'cap-owner')
            query('UPDATE tipi_invite_redemptions SET online_seconds = 180000 WHERE invitee = ?', [cid])
        award_plans = [plans(store.award(cid,'cap-owner')) for cid in ['cap-50','cap-51']]

        def parallel(plan):
            conn=pymysql.connect(**options, autocommit=True, cursorclass=pymysql.cursors.DictCursor)
            try: execute_plan(plan, conn)
            finally: conn.close()

        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            list(pool.map(parallel, award_plans))
        assert coin('cap-owner') == 14850
        assert sorted([coin('cap-50'),coin('cap-51')]) == [0,50]
        assert sorted([row('cap-50')['reward_state'],row('cap-51')['reward_state']]) == ['exhausted','paid']
        assert query("SELECT COUNT(*) n FROM tipi_invite_reward_log WHERE citizenid='cap-owner' AND kind='milestone'")[0]['n'] == 5
        check('All milestone amounts; concurrent 50th/51st awards never exceed cap')

        account('after-cap'); redeem('after-cap','cap-owner')
        assert not query('SELECT * FROM tipi_invite_redemptions WHERE invitee=?',['after-cap'])
        redeem('after-cap','cap-owner',True); complete('after-cap','cap-owner')
        assert row('after-cap')['reward_state'] == 'exhausted' and coin('after-cap') == 0
        tx(store.fraud('cap-1','console',True,'late')); tx(store.fraud('cap-1','console',False,'restore'))
        tx(store.reconcile('cap-owner'))
        assert coin('cap-owner') == 14850
        check('Full-cap confirmation; no refund of slots or repeat milestones after fraud reversal')

        account('rollback-owner'); account('rollback'); redeem('rollback','rollback-owner')
        query("CREATE TRIGGER fail_coin BEFORE UPDATE ON players FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='test rollback'")
        query('UPDATE tipi_invite_redemptions SET online_seconds = 180000 WHERE invitee=?',['rollback'])
        try:
            tx(store.award('rollback','rollback-owner'))
            raise AssertionError('Expected injected DB failure')
        except pymysql.MySQLError: pass
        assert row('rollback')['reward_state'] == 'pending' and row('rollback')['reward_slot'] is None
        assert not query('SELECT * FROM tipi_invite_reward_log WHERE citizenid IN (?,?)',['rollback','rollback-owner'])
        query('DROP TRIGGER fail_coin'); tx(store.award('rollback','rollback-owner'))
        assert coin('rollback') == 50 and coin('rollback-owner') == 100
        check('DB failure rolls back qualification, slot, ledger and coins; retry succeeds')

        account('race-owner'); account('race-a', license='shared'); account('race-b', license='shared')
        race_plans=[plans(store.redeem(cid,'race-owner',False)) for cid in ['race-a','race-b']]
        with concurrent.futures.ThreadPoolExecutor(2) as pool: list(pool.map(parallel,race_plans))
        assert query('SELECT COUNT(*) n FROM tipi_invite_redemptions WHERE inviter=?',['race-owner'])[0]['n']==1
        check('Concurrent duplicate identity redemptions admit only one account')

        # Exercise actual runtime session functions with real SQL and a controlled server clock.
        lua.globals().NewImpl = lambda _: lua.table()
        lua.globals().RefreshPlayerCoinByCitizenid = lambda _: None
        def sql_args(args):
            return [args[i] for i in range(1,len(args)+1)] if args else ()

        def scalar(sql,args=None):
            rows=query(sql,sql_args(args))
            return next(iter(rows[0].values()),None) if rows else None

        def single(sql,args=None):
            rows=query(sql,sql_args(args))
            if not rows: return None
            # Match oxmysql's installed TINYINT(1) => boolean type cast.
            data=rows[0]
            for key in ['auto_fraud','admin_fraud','identity_ready','owner_fraud','owner_ready']:
                if key in data: data[key]=bool(data[key])
            return lua.table_from(data)

        lua.globals().MySQL = lua.table_from({
            'transaction': lua.table_from({'await': tx}),
            'scalar': lua.table_from({'await': scalar}),
            'single': lua.table_from({'await': single}),
            'query': lua.table_from({'await': lambda sql,args=None: lua.table_from([lua.table_from(x) for x in query(sql,sql_args(args))])}),
        })
        lua.execute('testNow=1000; os.time=function() return testNow end; testPlayers={}; GetPlayerFromId=function(src) return testPlayers[src] end; GetPlayerIdentifiers=function(src) return {"license:"..testPlayers[src].identifier} end; GetNumPlayerTokens=function() return 2 end; GetPlayerToken=function(src,i) return testPlayers[src].identifier..i end')
        runtime = lua.execute((ROOT/'server/impl/InviteCode.impl.lua').read_text(encoding='utf-8') + '\nreturn {attach=attach, flush=flush, endSource=endSource, awards=awards, state=state}')
        account('lifecycle'); redeem('lifecycle','owner')
        lua.globals().testPlayers[7]=lua.table_from({'identifier':'lifecycle'})
        runtime.attach(7,1000,0)
        lua.globals().testNow=1030; runtime.flush(); runtime.flush()
        assert row('lifecycle')['online_seconds']==30
        query('UPDATE players SET playtime = playtime + 99999999 WHERE citizenid=?',['lifecycle'])
        runtime.flush()
        assert row('lifecycle')['online_seconds']==30
        lua.globals().testNow=1040; runtime.endSource(7); lua.globals().testPlayers[7]=None
        lua.globals().testNow=9000; runtime.flush()
        assert row('lifecycle')['online_seconds']==40
        lua.globals().testPlayers[7]=lua.table_from({'identifier':'lifecycle'})
        runtime.attach(7,9000,1); lua.globals().testNow=9020; runtime.flush()
        assert row('lifecycle')['online_seconds']==60
        check('Actual runtime: reconnect excludes offline time, unload freezes timestamp, flush cannot double count')
        runtime.endSource(7); runtime.flush()
        account('other-character'); redeem('other-character','owner')
        lua.globals().testPlayers[7]=lua.table_from({'identifier':'other-character'})
        runtime.attach(7,9020,2); lua.globals().testNow=9050; runtime.flush()
        assert row('other-character')['online_seconds']==30 and row('lifecycle')['online_seconds']==60
        # New module instance models restart: the durable checkpoint is retained, no old clock is resumed.
        runtime2=lua.execute((ROOT/'server/impl/InviteCode.impl.lua').read_text(encoding='utf-8')+'\nreturn {attach=attach, flush=flush}')
        lua.globals().testNow=10000; runtime2.attach(7,10000,0)
        lua.globals().testNow=10030; runtime2.flush()
        assert row('other-character')['online_seconds']==60
        check('VIP playtime ignored, source reuse isolates characters, resource restart resumes from durable seconds')
        assert runtime.state('a')['redemption']['status']=='qualified'
        assert runtime.state('fraud-before')['redemption']['status']=='rejected'
        assert runtime.state('fraud-before')['blocked'] is True
        assert runtime.state('after-cap')['redemption']['status']=='exhausted'
        check('NUI state handles oxmysql boolean flags and paid/rejected/exhausted statuses')
        account('balance')
        lua.globals().MySQL['update']=lua.table_from({'await':lambda sql,args=None: query(sql,sql_args(args))})
        lua.execute('''exports={qbx_core={GetPlayer=function(_,src)
            return {PlayerData={citizenid='balance',source=src,charinfo={},money={},metadata={}},Functions={}} end}};
            AddEventHandler=function() end; syncedCoin=nil;
            TriggerClientEvent=function(_,_,amount) syncedCoin=amount end''')
        lua.execute((ROOT/'server/bridge.lua').read_text(encoding='utf-8'))
        wrapped=lua.globals().GetPlayerFromId(42)
        assert wrapped.getAccount('coin')['money']==0
        assert wrapped.addAccountMoney('coin',100) is True
        query("UPDATE players SET coin=coin+50 WHERE citizenid='balance'")
        assert wrapped.addAccountMoney('coin',10) is True and coin('balance')==160
        assert wrapped.removeAccountMoney('coin',20) is True and coin('balance')==140
        assert wrapped.removeAccountMoney('coin',10000) is False and coin('balance')==140
        assert lua.globals().syncedCoin==140
        check('Actual Coin bridge preserves concurrent external credit, prevents overdraft and synchronizes committed balance')
        print(f'{len(passed)} integration groups passed; isolated database only.')
    finally:
        db.close()
        assert re.fullmatch(r'tipi_invite_test_[0-9a-f]{12}',database)
        with admin.cursor() as cur: cur.execute(f'DROP DATABASE `{database}`')
        admin.close()


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--config',required=True)
    run(parser.parse_args().config)
