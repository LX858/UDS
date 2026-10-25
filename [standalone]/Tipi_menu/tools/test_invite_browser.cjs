const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const output = process.env.INVITE_SCREENSHOTS || path.join(require('node:os').tmpdir(), 'tipi-invite-browser');
fs.mkdirSync(output, {recursive:true});
(async () => {
  const browser = await chromium.launch({ executablePath: process.env.BROWSER_EXECUTABLE || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', headless: true });
  const context = await browser.newContext({ viewport: {width:1366,height:768}, permissions:['clipboard-read','clipboard-write'] });
  const page = await context.newPage();
  await page.addInitScript(() => { window.GetParentResourceName=()=> 'nui-frame-app'; });
  const errors=[]; page.on('pageerror',e=>errors.push(e.message));
  let state={ok:true,code:'ABCDEFGH2345',blocked:false,canRedeem:true,playtimeSeconds:18000,maxRedeemPlaytimeSeconds:18000,requiredSeconds:180000,maxRewarded:50,inviteeCoin:50,inviterCoin:100,
    counts:{valid:5,pending:7,rejected:1,used:5},totalCoin:750,
    milestones:[{count:1,coin:0},{count:5,coin:250},{count:10,coin:600},{count:20,coin:1500},{count:30,coin:2500},{count:50,coin:5000}].map(m=>({...m,reached:m.count<=5,received:m.count===5}))};
  const calls=[];
  await page.route('https://nui-frame-app/**',async route=>{
    const action=new URL(route.request().url()).pathname.slice(1);
    let result={};
    if(action==='inviteCode:getState') result=state;
    if(action==='inviteCode:redeem') {
      const body=route.request().postDataJSON(); calls.push(body);
      if(!body.confirmExhausted) result={ok:false,needsExhaustedConfirmation:true,message:'Mã này đã hết 50 suất. Nếu tiếp tục, cả bạn và người mời đều không nhận Coin từ lượt này.'};
      else {state={...state,redemption:{code:body.code,seconds:0,status:'pending',ownerSlotsUsed:50}};result={...state,message:'Đã lưu mã mời.'};}
    }
    await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify(result)});
  });
  await page.goto(process.env.INVITE_PREVIEW_URL || 'http://127.0.0.1:5176/',{waitUntil:'networkidle'});
  await page.evaluate(()=>{
    window.postMessage({action:'setPlayerInfo',data:{name:'Người chơi',id:1,job:'Công dân',phoneNumber:'0123456789',age:'10 tuổi',timeRegistered:1727117365000}},'*');
    window.postMessage({action:'setShow',data:true},'*');
  });
  await page.getByRole('button',{name:'Mã mời',exact:true}).click();
  const panel=page.getByRole('region',{name:'Mã mời'});
  await panel.getByText('ABCDEFGH2345',{exact:true}).waitFor();
  await panel.getByRole('button',{name:'Sao chép',exact:true}).click();
  assert.equal(await page.evaluate(()=>navigator.clipboard.readText()),state.code);
  for(const size of [{width:1366,height:768},{width:1920,height:1080},{width:1280,height:720}]) {
    await page.setViewportSize(size);
    await page.waitForFunction(()=>{
      const el=document.querySelector('section[aria-label="Mã mời"]');
      if(!el)return false;const r=el.getBoundingClientRect();
      return r.bottom<=innerHeight+1&&r.right<=innerWidth+1;
    });
    const box=await panel.boundingBox();
    assert(box&&box.y>=0&&box.y+box.height<=size.height+1,JSON.stringify({size,box}));
    assert(await panel.evaluate(el=>el.scrollWidth<=el.clientWidth+1));
    await page.screenshot({path:path.join(output,`invite-${size.width}.png`)});
  }
  await panel.getByLabel('Nhập mã người đã mời bạn').fill('ZXCVBNMA2345');
  const submit=panel.getByRole('button',{name:'Xác nhận nhập mã',exact:true});
  assert(await submit.isDisabled());
  await panel.getByRole('checkbox').check();
  await submit.click();
  await panel.getByRole('button',{name:'Vẫn nhập mã — không nhận Coin',exact:true}).waitFor();
  assert.equal(calls.length,1); assert.equal(calls[0].confirmExhausted,false);
  await panel.getByRole('button',{name:'Vẫn nhập mã — không nhận Coin',exact:true}).click();
  await panel.getByText('Mã đã nhập — không thể thay đổi',{exact:true}).waitFor();
  assert.equal(calls.length,2); assert.equal(calls[1].confirmExhausted,true);
  assert.equal(await panel.getByRole('checkbox').count(),0);
  for(const [status,text] of [['verification','Chờ xác minh tài khoản'],['rejected','Không đủ điều kiện tham gia'],['qualified','Hợp lệ — đã nhận thưởng'],['exhausted','Hợp lệ — không được thưởng do hết 50 suất']]) {
    state={...state,redemption:{...state.redemption,seconds:180000,status}};
    await panel.getByRole('button',{name:'Tải lại',exact:true}).click();
    await panel.getByText(text,{exact:true}).waitFor();
  }
  await page.screenshot({path:path.join(output,'invite-exhausted.png')});
  await panel.getByText('Mốc 6 · 50 người',{exact:false}).scrollIntoViewIfNeeded();
  await page.screenshot({path:path.join(output,'invite-milestones.png')});
  state={...state,redemption:undefined,canRedeem:false,playtimeSeconds:18001,
    redeemBlockReason:'Bạn đã chơi trên 5 tiếng nên không thể nhập mã mời nữa.'};
  await panel.getByRole('button',{name:'Tải lại',exact:true}).click();
  await panel.getByText(state.redeemBlockReason,{exact:true}).waitFor();
  assert.equal(await panel.getByLabel('Nhập mã người đã mời bạn').count(),0);
  assert.equal(await panel.getByRole('button',{name:'Sao chép',exact:true}).count(),1);
  assert.deepEqual(errors,[]);
  console.log('PASS: 3 viewports, copy, acknowledgement, exhausted-cap confirmation, immutable redemption, 4 statuses, >5-hour entry lock, no page errors.');
  await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
