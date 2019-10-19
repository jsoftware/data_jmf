NB. jmf - main definitions except map,unmap
NB.
NB.  additem
NB.  createjmf
NB.  share
NB.  showle
NB.  showmap

NB. =========================================================
NB.*createjmf v create mapped file
NB. createjmf fn;msize
createjmf=: 3 : 0
'fn msize'=. y
fn=. jpath fn
msize=. <. msize
ts=. HS+msize     NB. total file size
if. IFUNIX do.
  fh=. 0 pick c_open fn; (OR O_RDWR, O_CREAT, O_TRUNC); 8b666
  c_lseek fh;(<:ts);SEEK_SET
  c_write fh; (,0{a.); 0+1   NB. place a single byte at the end
  c_lseek fh;0 ;SEEK_SET
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  c_write fh;d;(SZI*#d)
  c_close fh
else.
  fh=. CreateFileR (uucp fn,{.a.);(GENERIC_READ+GENERIC_WRITE);0;NULLPTR;CREATE_ALWAYS;0;0
  SetFilePointerR fh;ts;NULLPTR;FILE_BEGIN
  SetEndOfFile fh
  SetFilePointerR fh;0;NULLPTR;FILE_BEGIN
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  WriteFile fh;d;(SZI*#d);(,0);<NULLPTR
  CloseHandleR fh
end.
i.0 0
)

NB. =========================================================
getflagsad=: 3 : 0
SZI+1{memr (symget <fullname y),0 4,JINT
)

NB. =========================================================
readonly=: 3 : 0
AFRO(17 b.)memr (getflagsad y),0 1,JINT
:
flagsad=. getflagsad y
flags=. memr flagsad,0 1,JINT
flags=. flags(17 b.)(26 b.)AFRO NB. off AFRO
flags=. flags(23 b.)AFRO*0~:x
flags memw flagsad,0 1,JINT
i. 0 0
)


NB. =========================================================
NB.*showmap v show all mappings
showmap=: 3 : 0
h=. 'name';'fn';'sn';'fh';'mh';'address';'header';'fsize';'jmf';'mt';'msize';'refs'
hads=. 6{"1 mappings
h,mappings,.(gethadmsize each hads),.refcount each hads
)
