let capsuleInput=false,lastMove=0;
window.addEventListener('message',e=>{if(e.data.action==='duiInput')capsuleInput=e.data.enabled===true});
function pointer(e,event){if(!capsuleInput)return;if(event==='move'&&performance.now()-lastMove<25)return;lastMove=performance.now();fetch('https://'+GetParentResourceName()+'/duiPointer',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({x:e.clientX/innerWidth,y:e.clientY/innerHeight,event,delta:e.deltaY||0})}).catch(()=>{})}
document.addEventListener('mousemove',e=>pointer(e,'move'));
document.addEventListener('mousedown',e=>{if(e.button===0)pointer(e,'down')});
document.addEventListener('mouseup',e=>{if(e.button===0)pointer(e,'up')});
document.addEventListener('wheel',e=>pointer(e,'wheel'));
document.addEventListener('keydown',e=>{if(capsuleInput&&e.key==='Escape')fetch('https://'+GetParentResourceName()+'/close',{method:'POST',body:'{}'}).catch(()=>{})});

