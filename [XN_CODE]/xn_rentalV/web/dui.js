const query=new URLSearchParams(location.search),kind=query.get('kind')||'service';
document.body.className=kind;
const root=document.getElementById('display');
let display={},data=null,vehicle='',plan='',account='',pending=false;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
async function post(name,payload){try{const r=await fetch('https://'+query.get('resource')+'/'+name,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});return await r.json()}catch{return{ok:false,error:'Lỗi kết nối'}}}
const money=n=>(data?.currency||'$')+Number(n).toLocaleString('en-US');
const picture=v=>'<img src="'+esc(v?.image||'images/'+(v?.model||'blista')+'.png')+'" alt="'+esc(v?.label||'Phương tiện')+'">';
function hero(v){return '<section class="hero"><div class="hero-label"><small>'+esc(v?.category||'THEO YÊU CẦU / HÀNH TRÌNH MỚI')+'</small><h2>'+esc(v?.label||v?.model||'Sultan')+'</h2></div><span class="tag">SẴN SÀNG LÊN ĐƯỜNG</span>'+picture(v)+'<div class="hero-bottom">ĐẦY BÌNH XĂNG <span>↗ NHẬN XE TỰ ĐỘNG</span></div></section>'}
function brand(){return '<div class="brand">'+esc(display.title||'ALLGAMERS')+'</div><div class="subtitle">'+esc(display.subtitle||'THUÊ XE TỰ ĐỘNG')+'</div>'}
function config(d){display=d||{};if(/^#[a-f0-9]{6}$/i.test(display.accent||''))document.body.style.setProperty('--accent',display.accent);document.body.classList.toggle('still',display.animation===false);document.body.style.setProperty('--speed',Math.max(2,Number(display.speed)||12)+'s')}
function render(){
 if(kind==='flow')return;
 if(kind==='header'){root.innerHTML=brand()+'<div class="ticker">'+esc(display.ticker||'')+'</div>';return}
 if(!data){root.innerHTML='<div class="idle">'+brand()+'<div class="eyebrow">THEO YÊU CẦU / NHANH CHÓNG & TIỆN LỢI</div><h1>Thành phố của bạn.<br>Hành trình của <em>bạn.</em></h1>'+hero({model:'sultan',label:'Sultan'})+'<p>Chọn xe trên màn hình này.<br>Nhận xe từ khoang bên cạnh bạn.</p><div class="footer">01 / CHỌN XE　　02 / NHẬN XE　　03 / KHỞI HÀNH</div></div>';return}
 const selected=data.vehicles.find(v=>v.id===vehicle),selectedPlan=data.plans.find(p=>p.id===plan);
 const price=Math.floor((selectedPlan?.price||0)*(selected?.multiplier||1));
 root.innerHTML='<div class="topbar">'+brand()+'<button class="close" data-action="close" aria-label="Đóng">×</button></div><div class="station">● '+esc(data.station.name||'TRẠM THUÊ XE')+'<span>TỰ PHỤC VỤ / AG</span></div><div class="heading"><div class="eyebrow">'+(data.rental?'XE BẠN ĐANG THUÊ':'DANH SÁCH XE / CHỌN XE CỦA BẠN')+'</div><h1>'+(data.rental?'Chào mừng trở lại.':'Tìm xe phù hợp.')+'</h1><p>'+(data.rental?'Một bước cuối cùng. Chúng tôi sẽ lo phần còn lại.':'Vài thao tác đơn giản. Chìa khóa trao tay.')+'</p></div>'+
 (data.rental?hero(data.vehicles.find(v=>v.model===data.rental.model)||data.rental)+'<div class="rental-stats"><div><small>BIỂN SỐ XE</small><strong>'+esc(data.rental.plate)+'</strong></div><div><small>THỜI GIAN CÒN LẠI</small><strong>'+Math.max(0,Math.ceil(data.rental.remaining/60))+' phút</strong></div></div><p class="instructions">'+(data.rental.recoverable?'Lượt thuê của bạn đã được giữ lại. Nhận lại xe để dùng tiếp thời gian còn lại, hoặc hủy nếu xe đã mất.':'Đỗ xe gần đây, sau đó mở khoang trả xe. Lái xe lên bệ nâng, xuống xe và xác nhận bên cạnh khoang.')+'</p><button class="primary" data-action="'+(data.rental.recoverable?'recover':'returnRental')+'">'+(data.rental.recoverable?'Nhận lại xe':'Mở khoang trả xe')+' <span>↗</span></button>'+(data.rental.recoverable?'<button class="secondary" data-action="cancelRental" style="margin-top:10px;width:100%">Hủy lượt thuê</button>':''):
 hero(selected)+'<div class="vehicles">'+data.vehicles.map(v=>'<button data-vehicle="'+esc(v.id)+'" class="vehicle '+(vehicle===v.id?'selected':'')+'">'+picture(v)+'<span>'+esc(v.label)+'</span><i>'+(vehicle===v.id?'✓':'↗')+'</i></button>').join('')+'</div><div class="section-label">01 / THỜI GIAN THUÊ</div><div class="plans">'+data.plans.map(p=>'<button data-plan="'+esc(p.id)+'" class="'+(plan===p.id?'selected':'')+'">'+p.minutes+' <small>PHÚT</small></button>').join('')+'</div><div class="section-label">02 / PHƯƠNG THỨC THANH TOÁN</div><div class="plans accounts">'+data.accounts.map(a=>'<button data-account="'+esc(a)+'" class="'+(account===a?'selected':'')+'">'+(a==='bank'?'▤　':'◈　')+esc(a==='bank'?'Thẻ ngân hàng':a==='cash'?'Tiền mặt':a)+'</button>').join('')+'</div><div class="balance">'+money(data.balance[account]||0)+' KHẢ DỤNG <span>Đã bao gồm xăng · Không cọc</span></div><div class="total">TỔNG TIỀN <strong>'+money(price)+'</strong></div><button class="primary" data-action="rent" '+(data.busy?'disabled':'')+'>Xác nhận thuê xe <span>↗</span></button>')+
 '<div class="error" id="error" role="status">'+(data.busy&&!data.rental?'Khoang đang di chuyển hoặc có xe. Vui lòng đợi.':'')+'</div><div class="footer">KHU VỰC NHẬN XE BÊN CẠNH QUẦY <span>HỆ THỐNG TỰ ĐỘNG</span></div>';
 if(pending)root.querySelectorAll('button').forEach(b=>b.disabled=true);
}
root.addEventListener('error',e=>{if(e.target.tagName==='IMG')e.target.style.visibility='hidden'},true);
window.addEventListener('message',e=>{const m=e.data;if(m.display)config(m.display);if(m.action==='idle'){data=null;pending=false}if(m.action==='busy'&&data)data.busy=m.busy;if(m.action==='menu'){data={...m.data,currency:m.currency};vehicle=data.vehicles[0]?.id;plan=data.plans[0]?.id;account=data.accounts[0];pending=false}render()});
root.addEventListener('click',async e=>{
 const b=e.target.closest('button');if(!b||b.disabled||pending)return;
 if(b.dataset.vehicle){vehicle=b.dataset.vehicle;render();return}
 if(b.dataset.plan){plan=b.dataset.plan;render();return}
 if(b.dataset.account){account=b.dataset.account;render();return}
 if(b.dataset.action){pending=true;render();const r=await post('duiAction',{action:b.dataset.action,vehicle,plan,account});pending=false;if(!r.ok){render();document.getElementById('error').textContent=r.error||'Vui lòng thử lại.'}}
});
render();post('duiReady',{kind});
