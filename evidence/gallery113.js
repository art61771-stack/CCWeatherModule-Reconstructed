const fs=require('fs'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync(__dirname+'/../Resources/Gallery.html','utf8');
class Element {constructor(tag){this.tagName=tag.toUpperCase();this.dataset={};this.children=[];this.top=0;this.textContent='';}append(...c){for(const x of c){x.parent=this;this.children.push(x)}}querySelector(s){return this.children.find(x=>x.tagName===s.toUpperCase())}remove(){if(this.parent)this.parent.children=this.parent.children.filter(x=>x!==this)}getBoundingClientRect(){return {top:this.top,bottom:this.top+100}}removeAttribute(k){delete this[k]}pause(){this.stopped=true}play(){return Promise.resolve()}load(){}}
const grid=new Element('main'),status=new Element('p');const events={};let frames=[];
const context={Map,innerHeight:300,document:{hidden:false,querySelector:s=>s==='#grid'?grid:status,createElement:t=>new Element(t),addEventListener:(k,v)=>events[k]=v},requestAnimationFrame:f=>frames.push(f),addEventListener:(k,v)=>events[k]=v};context.window=context;vm.createContext(context);vm.runInContext(html.match(/<script>([\s\S]*)<\/script>/)[1],context);
const count=()=>vm.runInContext('running.size',context),tick=()=>{while(frames.length)frames.shift()()};
assert.equal(count(),0);context.populate(Array.from({length:60},(_,id)=>({id,name:id===0?'<script>private name</script>':'icon'+id,video:id%2===0})), 'directory diagnostic');
grid.children.forEach((c,i)=>c.top=i*110);tick();assert.equal(count(),2);assert.equal(grid.children[0].querySelector('small').textContent,'<script>private name</script>');
assert.equal(grid.children[0].querySelector('figure').children[0].src,'wcc-media://media/0');
grid.children.forEach(c=>c.top-=550);events.scroll();tick();assert.equal(count(),2);assert.equal(grid.children[0].querySelector('figure').children.length,0);
context.pauseGallery();assert.equal(count(),0);context.resumeGallery();assert.equal(count(),2);
let running=vm.runInContext('[...running.values()]',context);running[0].onerror();assert(count()<=2);assert.equal(vm.runInContext('cards.filter(c=>c.dataset.failed).length',context),1);
context.document.hidden=true;events.visibilitychange();assert.equal(count(),0);context.document.hidden=false;events.visibilitychange();assert(count()<=2);
assert(!html.includes('base64'));assert(html.length<6000);console.log('PASS actual production Gallery.html script: initial shell empty; max two visible media; scroll unload; pause/resume; error exclusion; text-only filenames; no data URI. DOM harness, not WKWebView/iOS test.');
