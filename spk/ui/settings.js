'use strict';
const fs=require('fs');
const [configFile,sharesFile,autostartFile,workspace]=process.argv.slice(2);
const emit=v=>process.stdout.write(JSON.stringify(v));
const read=(p,d)=>{try{return JSON.parse(fs.readFileSync(p,'utf8'));}catch(_){return d;}};
if((process.env.REQUEST_METHOD||'GET')==='GET'){
  const config=read(configFile,{}), index=read(sharesFile,{shares:[]});
  let allowed=Array.isArray(config.allowedDirectories)?config.allowedDirectories:[];
  if(!allowed.length) allowed=[workspace];
  emit({shares:index.shares||[],allowedDirectories:allowed,autostart:!fs.existsSync(autostartFile)||fs.readFileSync(autostartFile,'utf8').trim()!=='false'});
}else{
  let body='';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data',c=>body+=c);
  process.stdin.on('end',()=>{
    try{
      const input=JSON.parse(body||'{}');
      if(!Array.isArray(input.sharedDirectories)||typeof input.autostart!=='boolean') throw new Error('设置格式无效');
      const index=JSON.parse(fs.readFileSync(sharesFile,'utf8'));
      const available=new Map((index.shares||[]).map(x=>[x.path,x]));
      const selected=[...new Set(input.sharedDirectories)];
      if(selected.some(p=>typeof p!=='string'||!available.has(p))) throw new Error('共享目录列表已变化，请刷新后重试');
      const config=JSON.parse(fs.readFileSync(configFile,'utf8'));
      config.allowedDirectories=[workspace,...selected];
      config.telemetryEnabled=false;
      const write=(file,value)=>{const tmp=file+'.tmp';fs.writeFileSync(tmp,value,{mode:0o660});fs.chmodSync(tmp,0o660);fs.renameSync(tmp,file);};
      write(configFile,JSON.stringify(config,null,2)+'\n');
      write(autostartFile,(input.autostart?'true':'false')+'\n');
      emit({ok:true,allowedDirectories:config.allowedDirectories,autostart:input.autostart});
    }catch(e){emit({error:'无法保存设置：'+String(e.message||e)});}
  });
}
