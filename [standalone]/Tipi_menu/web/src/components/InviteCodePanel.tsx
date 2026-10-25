import { useCallback, useEffect, useRef, useState } from 'react'
import styled from 'styled-components'
import { fetchNui } from '../utils/fetchNui'
import { menuCardBase } from '../styles/menuCardStyles'

export type InviteState = {
  ok: boolean
  message?: string
  needsExhaustedConfirmation?: boolean
  code: string
  blocked: boolean
  canRedeem: boolean
  redeemBlockReason?: string
  maxRedeemPlaytimeSeconds: number
  playtimeSeconds?: number
  requiredSeconds: number
  maxRewarded: number
  inviteeCoin: number
  inviterCoin: number
  counts: { valid: number; pending: number; rejected: number; used: number }
  redemption?: { code: string; seconds: number; status: string; ownerSlotsUsed: number }
  milestones: { count: number; coin: number; received: boolean; reached: boolean }[]
  totalCoin: number
}

const Panel = styled.section`
  ${menuCardBase}
  flex: 1; min-height: 0; overflow: auto; padding: 14px; color: var(--text-main, #fff);
  scrollbar-width: none;
  &::-webkit-scrollbar { display: none; }
  font-family: 'Montserrat', sans-serif; font-size: 12px; line-height: 1.5;
  display: flex; flex-direction: column; gap: 14px;
  h3, p { margin: 0; }
  h3 { font-size: 13px; letter-spacing: .05em; text-transform: uppercase; }
  small { color: var(--text-sub, #9db3c5); font-size: 11px; }
  button { border: 1px solid var(--border, #225b72); border-radius: 5px; padding: 8px 10px;
    background: rgba(0, 229, 255, .12); color: var(--cyan, #00e5ff); cursor: pointer; font: inherit; }
  button:disabled { opacity: .45; cursor: not-allowed; }
  button:focus-visible, input:focus-visible { outline: 2px solid var(--cyan, #00e5ff); outline-offset: 2px; }
  input { width: 100%; min-width: 0; padding: 10px; border: 1px solid var(--border-dim, #1c4058);
    border-radius: 5px; background: rgba(0, 10, 22, .8); color: #fff; font: inherit; box-sizing: border-box; }
  progress { width: 100%; height: 8px; accent-color: var(--cyan, #00e5ff); }
  progress::-webkit-progress-bar { background: rgba(0, 229, 255, .1); border-radius: 4px; }
  progress::-webkit-progress-value { background: var(--cyan, #00e5ff); border-radius: 4px; }
`
const Row = styled.div`display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap;`
const OwnCode = styled.code`font-size: clamp(14px, 1vw, 20px); color: var(--cyan, #00e5ff); letter-spacing: .12em; user-select: all;`
const Stats = styled.div`
  display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px;
  > div { background: rgba(0, 229, 255, .05); border: 1px solid var(--border-dim, #1c4058); border-radius: 5px; padding: 8px 5px; text-align: center; }
  strong { display: block; font-size: 18px; } small { font-size: 10px; }
`
const Notice = styled.p`padding: 9px; border-left: 2px solid #e7b75b; background: rgba(231, 183, 91, .07); color: #f1d49d; font-size: 11px;`
const Form = styled.form`display: flex; flex-direction: column; gap: 9px;`
const Milestones = styled.div`
  display: flex; flex-direction: column; gap: 5px;
  > div { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 8px;
    border: 1px solid var(--border-dim, #1c4058); border-radius: 5px; }
  > div[data-received='true'] { border-color: #257763; background: rgba(61, 201, 150, .07); }
  b { font-size: 11px; } span { text-align: right; font-size: 11px; } small { display: block; font-size: 10px; }
`

const statuses: Record<string, string> = {
  pending: 'Đang tích lũy giờ online',
  verification: 'Chờ xác minh tài khoản',
  rejected: 'Không đủ điều kiện tham gia',
  processing: 'Đủ điều kiện — đang xử lý thưởng',
  qualified: 'Hợp lệ — đã nhận thưởng',
  exhausted: 'Hợp lệ — không được thưởng do hết 50 suất',
}
const number = (value: number) => value.toLocaleString('vi-VN')

export default function InviteCodePanel() {
  const [state, setState] = useState<InviteState | null>(null)
  const [code, setCode] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [confirmed, setConfirmed] = useState(false)
  const [exhaustedCode, setExhaustedCode] = useState<string | null>(null)
  const request = useRef(0)
  const submitting = useRef(false)
  const mounted = useRef(true)
  const refresh = useCallback(async () => {
    if (submitting.current) return
    const id = ++request.current
    try {
      const result = await fetchNui<InviteState>('inviteCode:getState')
      if (!mounted.current || id !== request.current) return
      if (result.ok) { setState(result); setMessage('') }
      else setMessage(result.message || 'Không tải được thông tin mã mời.')
    } catch {
      if (mounted.current && id === request.current) setMessage('Không thể kết nối. Bấm Tải lại để thử lại.')
    }
  }, [])
  useEffect(() => {
    mounted.current = true
    void refresh()
    const timer = window.setInterval(() => { void refresh() }, 30000)
    return () => { mounted.current = false; request.current++; window.clearInterval(timer) }
  }, [refresh])

  const submit = async () => {
    if (submitting.current || !confirmed || !code.trim()) return
    submitting.current = true; setBusy(true); setMessage(''); request.current++
    try {
      const result = await fetchNui<InviteState>('inviteCode:redeem', {
        code: code.trim().toUpperCase(), confirmExhausted: exhaustedCode === code.trim().toUpperCase(),
      })
      if (!mounted.current) return
      setMessage(result.message || (result.ok ? 'Đã lưu mã mời.' : 'Không thể nhập mã mời.'))
      if (result.ok) { setState(result); setExhaustedCode(null) }
      else if (result.needsExhaustedConfirmation) setExhaustedCode(code.trim().toUpperCase())
    } catch {
      if (mounted.current) setMessage('Chưa nhận được phản hồi. Bấm Tải lại để kiểm tra trước khi thử lại.')
    } finally {
      submitting.current = false
      if (mounted.current) setBusy(false)
    }
  }
  const copy = async () => {
    if (!state) return
    try {
      if (navigator.clipboard?.writeText) await navigator.clipboard.writeText(state.code)
      else {
        const input = document.createElement('textarea')
        input.value = state.code; input.style.position = 'fixed'; input.style.opacity = '0'
        document.body.appendChild(input); input.select()
        const copied = document.execCommand('copy'); input.remove()
        if (!copied) throw new Error('clipboard unavailable')
      }
      setMessage('Đã sao chép mã mời.')
    } catch { setMessage('Chưa thể sao chép. Hãy chọn mã và nhấn Ctrl+C.') }
  }

  return <Panel aria-label='Mã mời'>
    <Row><h3>Mã mời của bạn</h3><button type='button' disabled={busy} onClick={() => void refresh()}>Tải lại</button></Row>
    {message && <Notice role='status' aria-live='polite'>{message}</Notice>}
    {!state ? <p>Đang chờ thông tin mã mời…</p> : <>
      <Row><OwnCode>{state.code}</OwnCode><button type='button' onClick={() => void copy()}>Sao chép</button></Row>
      <Stats>
        <div><strong>{number(state.counts.valid)}</strong><small>Hợp lệ</small></div>
        <div><strong>{number(state.counts.pending)}</strong><small>Đang chờ</small></div>
        <div><strong>{number(state.counts.rejected)}</strong><small>Bị loại</small></div>
      </Stats>
      <Row><small>Suất đã dùng: {state.counts.used}/{state.maxRewarded}</small><small>Đã nhận: {number(state.totalCoin)} Coin</small></Row>
      {state.blocked && <Notice>Tài khoản hiện không đủ điều kiện tham gia chương trình mã mời.</Notice>}
      {!state.redemption && !state.blocked && state.canRedeem === false &&
        <Notice>{state.redeemBlockReason || 'Bạn không đủ điều kiện nhập mã mời.'}</Notice>}
      {state.redemption ? <div>
        <small>Mã đã nhập — không thể thay đổi</small><p><b>{state.redemption.code}</b></p>
        <p>{statuses[state.redemption.status] || 'Chờ xử lý'}</p>
        <progress value={state.redemption.seconds} max={state.requiredSeconds} aria-label='Tiến độ giờ online' />
        <Row><small>{(state.redemption.seconds / 3600).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} / {state.requiredSeconds / 3600} giờ online</small>
          <small>Chủ mã đã dùng {state.redemption.ownerSlotsUsed}/{state.maxRewarded} suất</small></Row>
      </div> : !state.blocked && state.canRedeem !== false && <Form onSubmit={e => { e.preventDefault(); void submit() }}>
        <label htmlFor='invite-code'>Nhập mã người đã mời bạn</label>
        <input id='invite-code' value={code} maxLength={12} autoComplete='off' spellCheck={false} disabled={busy}
          placeholder='Mã mời gồm 12 ký tự' onChange={e => { setCode(e.target.value.toUpperCase()); setExhaustedCode(null); setConfirmed(false) }} />
        <Notice>Chỉ được nhập mã khi tổng giờ chơi hiện tại dưới {(state.maxRedeemPlaytimeSeconds ?? 3600) / 3600} tiếng.
          Mã chỉ được nhập một lần và không thể thay đổi. Cần đủ 50 giờ online sau khi nhập mã và vượt qua kiểm tra.
          Chỉ 50 người đủ điều kiện đầu tiên của chủ mã được thưởng; nhập mã không giữ suất.</Notice>
        <label style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
          <input type='checkbox' checked={confirmed} disabled={busy} style={{ width: 'auto', marginTop: 3 }} onChange={e => setConfirmed(e.target.checked)} />
          <small>Tôi hiểu mã không thể đổi và việc nhập mã không bảo đảm còn suất thưởng.</small>
        </label>
        {exhaustedCode && <Notice>Mã này đã hết 50 suất. Cả bạn và người mời sẽ không nhận Coin từ lượt này. Bấm nút dưới để xác nhận vẫn nhập.</Notice>}
        <button type='submit' disabled={busy || !confirmed || code.trim().length !== 12}>
          {busy ? 'Đang lưu…' : exhaustedCode ? 'Vẫn nhập mã — không nhận Coin' : 'Xác nhận nhập mã'}
        </button>
      </Form>}
      <div><h3>Phần thưởng mời bạn</h3>
        <small>Mỗi lượt được thưởng: bạn nhận {state.inviterCoin} Coin, người được mời nhận {state.inviteeCoin} Coin.</small></div>
      <Milestones>{state.milestones.map((m, i) => <div key={m.count} data-received={m.received}>
        <b>Mốc {i + 1} · {m.count} người<small>{Math.min(state.counts.valid, m.count)}/{m.count} hợp lệ</small></b>
        <span>{m.coin ? `+${number(m.coin)} Coin` : '100 Coin / lượt đầu'}
          <small>{m.received ? 'Đã nhận' : m.reached ? (m.coin > 0 ? 'Đang xử lý' : 'Đã đạt') : 'Chưa đạt'}</small></span>
      </div>)}</Milestones>
      <small>Thưởng mốc cộng thêm một lần. Lượt gian lận bị loại khỏi số người hợp lệ; Coin đã trả và suất đã dùng không được hoàn lại.</small>
    </>}
  </Panel>
}
