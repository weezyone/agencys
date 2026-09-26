import os,json,sys,re
root=sys.argv[1]; out=[]
for d in sorted(os.listdir(root)):
    p=os.path.join(root,d)
    if not os.path.isdir(p): continue
    inner=os.listdir(p)
    if len(inner)==1: p=os.path.join(p,inner[0])
    files=[];pk=[]
    for r,ds,fs in os.walk(p):
        ds[:]=[x for x in ds if x not in('node_modules','.git','.next','dist')]
        for f in fs:
            files.append(os.path.relpath(os.path.join(r,f),p))
            if f=='package.json': pk.append(os.path.join(r,f))
    code=[f for f in files if re.search(r'\.(ts|tsx|js|jsx|py)$',f)]
    loc=0
    for f in code:
        try: loc+=sum(1 for _ in open(os.path.join(p,f),encoding='utf8',errors='ignore'))
        except: pass
    info={'name':d,'path':p,'files':len(files),'code':len(code),'loc':loc,'pkgs':[]}
    for f in pk:
        try: j=json.load(open(f,encoding='utf8'))
        except Exception as e: continue
        deps=list((j.get('dependencies') or {}).keys())+list((j.get('devDependencies') or {}).keys())
        key=[x for x in deps if re.search(r'next|mastra|ai-sdk|^ai$|openai|mongo|prisma|drizzle|supabase|express|react$|vite|langchain|anthropic|convex|stripe|trpc|hono',x)]
        info['pkgs'].append({'at':os.path.relpath(f,p),'scripts':list((j.get('scripts') or {}).items())[:6],'key':key})
    py=[f for f in files if f.endswith(('requirements.txt','pyproject.toml'))]
    info['py']=py
    envs=[f for f in files if '.env' in os.path.basename(f)]
    info['env']=envs
    top=sorted(set(f.split(os.sep)[0] for f in files))[:25]
    info['top']=top
    rd=[f for f in files if f.lower()=='readme.md']
    info['readme']=open(os.path.join(p,rd[0]),encoding='utf8',errors='ignore').read()[:400].replace('\n',' ') if rd else ''
    out.append(info)
json.dump(out,open(os.path.join(root,'_inventory.json'),'w'),indent=1)
for i in out:
    print('=== ',i['name'],'files',i['files'],'code',i['code'],'loc',i['loc'])
    print(' top:',i['top'])
    for k in i['pkgs'][:4]: print(' pkg',k['at'],'key',k['key'][:12],'scripts',[s[0] for s in k['scripts']])
    if i['py']: print(' py',i['py'][:4])
    print(' env',i['env'][:4]); print(' readme:',i['readme'][:250])
