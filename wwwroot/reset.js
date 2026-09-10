const configUrl='/api/config';
let cfg={}, accessToken='';
const $=s=>document.querySelector(s);
function hashParams(){return new URLSearchParams(location.hash.replace(/^#/,''))}
function message(text,ok=false){$('#reset-message').textContent=text;$('#reset-message').style.color=ok?'#22713d':''}
async function init(){
  try{cfg=await fetch(configUrl).then(r=>r.json())}catch{message('เชื่อมต่อระบบไม่ได้ กรุณาลองใหม่อีกครั้ง');return}
  const p=hashParams();
  if(p.get('error_code')==='otp_expired'||p.get('error')||p.get('error_description')){ $('#reset-hint').textContent='ลิงก์นี้หมดอายุหรือถูกใช้งานแล้ว';message('กรุณากลับไปขออีเมลรีเซ็ตรหัสผ่านฉบับใหม่ แล้วกดลิงก์ภายในอีเมลฉบับล่าสุด');return }
  accessToken=p.get('access_token');
  if(!accessToken){$('#reset-hint').textContent='ไม่พบสิทธิ์สำหรับรีเซ็ตรหัสผ่าน';message('เปิดหน้านี้จากลิงก์ในอีเมลรีเซ็ตรหัสผ่านเท่านั้น');return}
  $('#reset-hint').textContent='กรอกรหัสผ่านใหม่สำหรับบัญชี Admin';$('#reset-form').classList.remove('hidden')
}
$('#reset-form').onsubmit=async e=>{e.preventDefault();const f=new FormData(e.target),password=f.get('password');if(password!==f.get('confirm')){message('รหัสผ่านทั้งสองช่องไม่ตรงกัน');return}try{const r=await fetch(`${cfg.supabaseUrl}/auth/v1/user`,{method:'PUT',headers:{apikey:cfg.supabaseAnonKey,Authorization:`Bearer ${accessToken}`,'Content-Type':'application/json'},body:JSON.stringify({password})});if(!r.ok)throw new Error(await r.text());message('เปลี่ยนรหัสผ่านสำเร็จแล้ว กำลังกลับหน้า Admin...',true);e.target.classList.add('hidden');history.replaceState({},document.title,'/reset.html');setTimeout(()=>location.href='/admin.html',1400)}catch{message('เปลี่ยนรหัสผ่านไม่สำเร็จ ลิงก์อาจหมดอายุ กรุณาขออีเมลใหม่')}};
init();
