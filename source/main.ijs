NB. jmf - main definitions except map,unmap

NB. =========================================================
NB.*additem v add item to mapped noun
NB.
NB. no longer necessary, but retained for compatibility
additem=: 3 : 0
had=. memhad fullname y
'flag msize type rank'=. (<.SZI%~HADFLAG,HADM,HADT,HADR){memr had,0,NORMAH,JINT
type=. nountype type
'not mapped and writeable' assert 2=flag
'scalar' assert 0~:rank
'not supported for boxed data' assert 32~:type
shape=. memr had,HADS,rank,JINT
shape=. shape+1,0#~rank-1
size=. (JTYPES i.type){JSIZES
ts=. size**/shape
'msize too small' assert ts<:msize
(*/shape) memw had,HADN,1,JINT
shape memw had,HADS,rank,JINT
rank setHADR had
i.0 0
)

NB. =========================================================
NB.*createjmf v create mapped file
NB. createjmf fn;msize
createjmf=: 3 : 0
'fn msize'=. y
fn=. jpath fn
msize=. <. msize
ts=. HS+msize     NB. total file size
if. IFUNIX do.
  if. ('Darwin'-:UNAME) *. 'arm64'-:3 :'try.9!:56''cpu''catch.''''end.' '' do.
NB. apple m1/ios variadic parameters always passing on stack
    fh=. 0 pick c_open_va fn; (OR O_RDWR, O_CREAT, O_TRUNC); (6#<00) ,< 8b666
  else.
    fh=. 0 pick c_open fn; (OR O_RDWR, O_CREAT, O_TRUNC); 8b666
  end.
  c_lseek fh;(<:ts);SEEK_SET
  c_write fh; (,0{a.); 0+1   NB. place a single byte at the end
  c_lseek fh;0 ;SEEK_SET
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  d=. d (SZI<.@%~HADK,HADFLAG,HADM,HADT,HADC,HADN,HADR,HADS)}HAD,0
  c_write fh;d;(SZI*#d)
  c_close fh
else.
  fh=. CreateFileR (uucp fn,{.a.);(GENERIC_READ+GENERIC_WRITE);0;NULLPTR;CREATE_ALWAYS;0;0
  SetFilePointerR fh;ts;NULLPTR;FILE_BEGIN
  SetEndOfFile fh
  SetFilePointerR fh;0;NULLPTR;FILE_BEGIN
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  d=. d (SZI<.@%~HADK,HADFLAG,HADM,HADT,HADC,HADN,HADR,HADS)}HAD,0
  WriteFile fh;d;(SZI*#d);(,0);<NULLPTR
  CloseHandleR fh
end.
i.0 0
)

NB. =========================================================
readonly=: 3 : 0
AFRO(17 b.) a.i.memr (HADFLAG+memhad fullname y),0 1,JCHAR
:
ad=. HADFLAG+memhad fullname y
flags=. a.i.memr ad,0 1,JCHAR
flags=. flags(17 b.)(26 b.)AFRO NB. off AFRO
flags=. flags(23 b.)AFRO*0~:x
(flags{a.) memw ad,0 1,JCHAR
i. 0 0
)

NB. =========================================================
NB.*showmap v show all mappings
showmap=: 3 : 0
h=. 'name';'fn';'sn';'fh';'mh';'address';'header';'fsize';'jmf';'mt';'msize';'refs'
hads=. 6{"1 mappings
h,mappings,.(gethadmsize each hads),.((1-initc) + refcount) each hads  NB. bias refcount for compatibility with original initc=1
)
