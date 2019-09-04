NB. map

NB. =========================================================
NB.*map v map a file
NB. [type [,trailing_shape]] map name;filename [;sharename;ro]
map=: 3 : 0
0 map y
:
if. 0=L.x do. t=. <&> x else. t=. x end.
'type tshape hsize'=. 3 {. t, a:
type =. nountype type

'trailing shape may not be zero' assert -. 0 e. tshape

'name fn sn ro'=. 4{.y,(#y)}.'';'';'';0
fn=. jpath fn
sn=. '/' (('\'=sn)#i.#sn)} sn NB. / not allowed in win sharename
name=. fullname name
c=. #mappings

'name already mapped'assert c=({."1 mappings)i.<name
'filename already mapped'assert c=(1{"1 mappings)i.<fn
'sharename already mapped'assert (''-:sn)+.c=(2{"1 mappings)i.<sn
4!:55 ::] <name
'bad noun name'assert ('_'={:name)*._1=nc<name

ro=. 0~:ro
NB. if readonly then use flag MAP_PRIVATE or FILE_MAP_COPY
NB. so that content never written back to original file
aa=. AFNJA+0[AFRO*ro       NB. readwrite/readonly array access

if. IFUNIX do.
  'Unix sharename must be same as filename' assert (sn-:'')+.sn-:fn
  ts=. 1!:4 <fn
  fh=. >0 { c_open fn;((0]ro){O_RDWR,O_RDONLY);0
  'bad file name/access' assert fh~:_1
NB.  unix doesn't use a mapping handle;
NB.  however, we need to keep the length in the mapping list.
  mh=. ts
NB.  hard wire some values : protection flags (3) == read & write
NB.     mapping flags (2) == private;  (1) == shared
  fad=. >0{ c_mmap (<0);ts;(OR (0[ro)}. PROT_WRITE, PROT_READ);(ro{MAP_SHARED,MAP_PRIVATE);fh;0
  if. fad e. 0 _1 do.
    'bad view' assert 0[free fh,mh,0
  end.
else.
  'fa ma va'=. ro{RW     NB. readwrite/readonly for file, map, view access
  fh=. CreateFileR (uucp fn,{.a.);fa;(OR ro}. FILE_SHARE_WRITE, FILE_SHARE_READ);NULLPTR;OPEN_EXISTING;0;0
  'bad file name/access'assert fh~:_1
  ts=. GetFileSizeR fh
  mh=: CreateFileMappingR fh;NULLPTR;ma;0;0;(0=#sn){(uucp sn,{.a.);<NULLPTR
  if. mh=0 do. 'bad mapping'assert 0[free fh,0,0 end.
  fad=. MapViewOfFileR mh;va;0;0;0
  if. fad=0 do.
    errno=. GetLastError''
    free fh,mh,0
    if. ERROR_NOT_ENOUGH_MEMORY-:errno do.
      'not enough memory' assert 0
    else.
      'bad view' assert 0
    end.
  end.
end.

if. ro*.0=type do. NB. readonly jmf file
  had=. allochdr 127
  d=. memr fad,0,HSN,JINT
  d=. (sfu HS+-/ufs fad,had),aa,2}.d NB. HADK HADFLAG
  d=. 1 HADCN} d
  d setheader had
elseif. 0=type do.
  had=. fad
  if. 0=validate ts,had do. 'bad jmf header' assert 0[free fh,mh,fad end.
  aa memw had,HADFLAG,1,JINT
  if. sn-:'' do.
    t=. 0
  else.
    t=. 10000+ getHADC had NB. shared ref count is bumped and is not valid
  end.
  (,t+1) setHADC had    NB. ref count is 1 (except for shared, which is bumped)
elseif. 1 do.
  had=. allochdr 127                   NB. allocate header
  'JBOXED (non-jmf) not supported' assert JBOXED~:type
  bx=. JBOXED=type
NB.  hs=. (+/hsize)*asize=. JSIZES {~ JTYPES i. type
NB. hsize should be in byte not atom, data knows nothing about items
  hs=. +/hsize [ asize=. JSIZES {~ JTYPES i. type
  lshape=. bx}.<.(ts-hs)%(*/tshape)*asize
  d=. sfu hs+-/ufs fad,had
  h=. d,aa,ts,type,1,(*/lshape,tshape),((-.bx)+#tshape),lshape,tshape
  h setheader had  NB. set header
end.

mappings=: mappings,name;fn;sn;fh;mh;fad;had
(name)=: symset had  NB. set name to address header
i.0 0
)

