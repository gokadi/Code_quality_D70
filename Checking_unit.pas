unit Checking_unit;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin(*, MSSPeller*),ComObj;
//��� ��� �����������:���������.,�����.����.����.,�����.����.,����� ����� ����.�����
type//��� ��� �����������:���������.,�����.����.����.,�����.����.,����� ����� ����.�����
  Tconstruction = record
    no_comm, comm_gram, comm_nogram, all_numb:integer;
end;
//�������� ��������� �����

var
  non:array of string;//(��� �����+������ ����� ��� ������������) ��� ����� �������
  mode:byte;//����� ���������������
  //����� ����������� � ������������ � �������
  procedure mode_1(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������
  procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������
  procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. �����
  procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������ � ������
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
//����������� ������
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
    g:=copy(line,tmp+2,length(line)(*-(tmp+1)*));//�� ����, ��� �������, �� � ��� ���� ��������
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
      non[p]:=inttostr(k+1);//� ������ �������� � 0-> (k+1)
      p:=p+1;//������� ������� � �������� ���������. �����
    end;
end;
//����������� ������
procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp:integer;
  line,g:string;
begin
  flag:=false;//���� �������������� ���������� ������������� �����������
  tmp:=pos('//',file_line.strings[k-1]);
  line:=file_line.strings[k-1];
  if (tmp<>0) then
    begin
       g:=copy(line,tmp+2,length(line));
       flag:=emptyComm(g);
    end;
  for i:=tmp-1 downto 1 do//��������, �� ���������� ������� ������ �����������
                              //����� �� �������� �����, �������� � ����������� � ���������� �������
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
      non[p]:=inttostr(k+1);//� ������ �������� � 0-> (k+1)
      p:=p+1;//������� ������� � �������� ���������. �����
    end;
end;
//����������� �����
procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp:integer;
  line,g:string;
begin
  flag:=false;//���� �������������� ���������� ������������� �����������
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
      non[p]:=inttostr(k+1);//� ������ �������� � 0-> (k+1)
      p:=p+1;//������� ������� � �������� ���������. �����
    end;
end;
//����������� ������ � ������    � �����
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

//�������� �� �������������� ������������
function grammatic(var comment:String):boolean;
var
  WordDoc:OLEVariant;
  IsMSWordNew:Boolean;
  FWordApp:Variant;
begin
//������������ � �����, ��������� ���
  try
    FWordApp:=GetActiveOleObject('Word.Application');
    IsMSWordNew:=False;//������� ����, ��� ������� ������������ � ������������� ���������� �����
  except
    FWordApp:=CreateOleObject('Word.Application');
    FWordApp.Visible:=False;
    IsMSWordNew:=True;//�������, ��� ���� ����� � ��� ���� ����� �������
  end;
  try//��� ���������������� ���������� �� �����
  //��� ���� ��������, ��� ��������� ������ ��������� ���� � ����� ����������� ������ ���� ������ ���� ���� ��������
    if FWordApp.Documents.Count<1 then
      WordDoc:=FWordApp.Documents.Add
    else
      WordDoc:=NULL;//�������, ��� ������ ��������� �� ����������� � ������������� ��� ��������� ���
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
//������� ������ ����� ����������� ������� � �������� ��� ����.������ setlength(non,1000)-�����,�� ���� �� ��������,��� ��-�������.
procedure non_clear();
var
  i:integer;
begin
  setlength(non,1000);
  for i:=0 to length(non)-1 do
    non[i]:='';
end;
end.
