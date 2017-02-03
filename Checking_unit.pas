unit Checking_unit;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin(*, MSSPeller*),ComObj;
//тип дл€ конструкций:непрокомм.,грамм.прав.комм.,грамм.непр.,общее число комм.строк
type//тип дл€ конструкций:непрокомм.,грамм.прав.комм.,грамм.непр.,общее число комм.строк
  Tconstruction = record
    no_comm, comm_gram, comm_nogram, all_numb:integer;
end;
//описание элементов формы

var
  non:array of string;//(им€ файла+номера строк без комментариев) дл€ всего проекта
  mode:byte;//режим комментировани€
  //поиск комментари€ в соответствии с режимом
  procedure mode_1(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. справа
  procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. сверху
  procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. снизу
  procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. справа и сверху
  function grammatic(var comment:String):boolean;
  function emptyComm(var g:String):boolean;
  procedure non_clear();
implementation
function emptyComm(var g:String):boolean;
var
  i:integer;
  f:boolean;
begin
  f:=false;
  for i:=(pos('//',g)+2) to Length(g) do
    if (g[i]<>'') or (g[i]<>' ') then begin f:=true; break; end
    else f:=false;
  Result:=f;
end;
//комментарии справа
procedure mode_1(const file_line:TStringList;var p:integer; const k:integer; var constr:Tconstruction);//
var     
  flag:boolean;
  g,line:string;
  tmp:integer;
begin
  flag:=false;
  line:=file_line.Strings[k];
  tmp:=pos('//',line);
  if tmp<>0 then
  begin
    g:=copy(line,tmp+2,length(line)(*-(tmp+1)*));//по идее, это уточн§ет, но и без него работает
    flag:=emptyComm(g);
  end;
  if flag=true then
  begin
    if grammatic(g)=true then
      constr.comm_gram:=constr.comm_gram+1
    else
      constr.comm_nogram:=constr.comm_nogram+1;
  end
  else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//в списке нумераци§ с 0-> (k+1)
      p:=p+1;//счетчик массива с номерами непрокомм. строк
    end;
end;
//комментарии сверху
procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp:integer;
  line,g:string;
begin
  flag:=false;//флаг принадлежности комментари§ анализируемой конструкции
  tmp:=pos('//',file_line.strings[k-1]);
  line:=file_line.strings[k-1];
  if (tmp<>0) then
    begin
       g:=copy(line,tmp+2,length(line));
       flag:=emptyComm(g);
    end;
  for i:=tmp-1 downto 1 do//проверка, на предыдущей строчке только комментарий
                              //иначе он веро§тнее всего, относитс§ к конструкции с предыдущей строчки
    begin
      if line[i]<>' ' then begin flag:=false; break; end;
    end;
  if flag=true then
    if grammatic(g)=true then
      constr.comm_gram:=constr.comm_gram+1
    else
      constr.comm_nogram:=constr.comm_nogram+1
  else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//в списке нумераци§ с 0-> (k+1)
      p:=p+1;//счетчик массива с номерами непрокомм. строк
    end;
end;
//комментарии снизу
procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp:integer;
  line,g:string;
begin
  flag:=false;//флаг принадлежности комментари§ анализируемой конструкции
  tmp:=pos('//',file_line.strings[k+1]);
  line:=file_line.strings[k+1];
  if (tmp<>0) then
    begin
      g:=copy(line,tmp+2,length(line)); 
      flag:=emptyComm(g);
    end;
  for i:=tmp-1 downto 1 do
    begin
      if line[i]<>' ' then begin flag:=false; break; end;
    end;
  if flag=true then
    if grammatic(g)=true then
      constr.comm_gram:=constr.comm_gram+1
    else
      constr.comm_nogram:=constr.comm_nogram+1
  else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//в списке нумераци§ с 0-> (k+1)
      p:=p+1;//счетчик массива с номерами непрокомм. строк
    end;
end;
//комментарии сверху и справа    и снизу
procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  i,tmp,tmp2,tmp3:integer;
  line,line2,line3,g:string;
begin
  line:=file_line.strings[k-1];
  line3:=file_line.strings[k+1];
  line2:=file_line.strings[k];
  tmp:=pos('//',line);
  tmp2:=pos('//',line2);
  tmp3:=pos('//',line3);
  if tmp2<>0 then mode_1(file_line,p,k,constr)
  else if tmp<>0 then mode_2(file_line,p,k,constr)
  else if tmp3<>0 then mode_3(file_line,p,k,constr);
end;

//проверка на грамматическую правильность
function grammatic(var comment:String):boolean;
var
  WordDoc:OLEVariant;
  IsMSWordNew:Boolean;
  FWordApp:Variant;
begin
//подключитьс€ к ворду, настроить его
  try
    FWordApp:=GetActiveOleObject('Word.Application');
    IsMSWordNew:=False;//признак того, что удалось подключитьс€ к сущесвтующему экземпл€ру ворда
  except
    FWordApp:=CreateOleObject('Word.Application');
    FWordApp.Visible:=False;
    IsMSWordNew:=True;//признак, что ворд новый и его надо будет закрыть
  end;
  try//дл€ гарантированного отключени€ от ворда
  //как было вы€снено, дл€ получени€ списка вариантов слов в ворде об€зательно должен быть создан хоть один документ
    if FWordApp.Documents.Count<1 then
      WordDoc:=FWordApp.Documents.Add
    else
      WordDoc:=NULL;//указать, что своего документа не создавалось и необходимости его закрывать нет
    if NOT FWordApp.CheckSpelling(comment) then
      Result:=false
    else
      Result:=true;
  finally
    if VarType(WordDoc) <> varNull then WordDoc.Close(False);
    if IsMSWordNew then
      FWordApp.Quit(False);
  end;
end;
//очистка строки перед заполнением данными о строчках без комм.делать setlength(non,1000)-плохо,но пока не придумал,как по-другому.
procedure non_clear();
var
  i:integer;
begin
  setlength(non,1000);
  for i:=0 to length(non)-1 do
    non[i]:='';
end;
end.
