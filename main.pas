unit main;
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin,ComObj,Checking_unit;
//��� ��� �����������:���������.,�����.����.����.,�����.����.,����� ����� ����.�����
{type//��� ��� �����������:���������.,�����.����.����.,�����.����.,����� ����� ����.�����
  Tconstruction = record
    no_comm, comm_gram, comm_nogram, all_numb:integer;
end;   }
//�������� ��������� �����
type
  TForm1 = class(TForm)
    Button1: TButton;//������� ������
    Button2: TButton;//�����
    Label1: TLabel;
    ComboBox1: TComboBox;//����� �����
    Button3: TButton;//���������
    Button4: TButton;//��������� ���
    SaveDialog1: TSaveDialog;
    Label2: TLabel;//����� ���������������
    Memo1: TMemo;//���� ��� ������ �����
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    SpinEdit1: TSpinEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblAmount: TLabel;
    Label8: TLabel;
    lblGram: TLabel;
    procedure Button1Click(Sender: TObject);//������� ������
    procedure Button2Click(Sender: TObject);//�����
    procedure ComboBox1Change(Sender: TObject);//����� ����� � ������� ��� ���������/���������
    procedure Button3Click(Sender: TObject);//���������
    procedure Button4Click(Sender: TObject);//��������� ���
    procedure SpinEdit1Change(Sender: TObject);//����� ������ ���������������
    procedure FormActivate(Sender: TObject);//��������� �����
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);//�������� �����
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;//
  types:array[1..20] of string;
  av_res:longint;//   ��������������
  types_amount:array[1..20] of integer;//������������ ����������
  types_weight:array[1..20] of integer;
  check_ready:boolean;//���� ��� �������� ������������ �������
  pas_list: TStringList;//������ ��� ��������� .dpr. ����� ��������� ������ ����� .pas
  proj_dir:string;//path ���������� �������
  file_path:string;//���� � ����� ��� �������� � memo
  mode:byte;//����� ���������������
  funcs,cyc,cond,tags,constrs,summ:Tconstruction;//������ � ������������ � ������������ � �������
  pas_open:TStringList;//������ ������������� �� ������ �������� �����
  //non:array of string;//(��� �����+������ ����� ��� ������������) ��� ����� �������
  //function grammatic(var comment:String):boolean;//�������� ����������� �� ����������
  procedure resurs(const pas_open:TStringList; const k:integer);//���������� �������������� (�����)
  procedure count_arr();//������� �������������� �� ��������
  //����� ����������� � ������������ � �������
 { procedure mode_1(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������
  procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������
  procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. �����
  procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//�. ������ � ������
  }procedure choose_mode(const pas_open:TStringList; var p:integer; const k:integer;var variab:Tconstruction);//����� ������ ���������������+������� ������ ����� ��� ��� ���� �����������
  procedure analys_common(const pas_open:TStringList; var p:integer; const k:integer;const diff:string);//����� ����������� diff � ����
  procedure tags_an_var(const pas_open:TStringList; var p:integer; const k:integer);//������ �� ����������
  //������������ ����� � ������� 1
  procedure make_out();
  procedure ini();
  //������ �������
  procedure analyz_all();
  //������������ ����� ���� �����������(+� ����.,��� ����. � �.�.)
  procedure summary();
  //������� ������ ����� ����������� ������� � �������� ��� ����.
  //procedure non_clear();
  procedure make_mark_amount();
  procedure make_mark_gram();



implementation

uses Math;

{$R *.dfm}
{*******************�������� �������� �����****************************}
//������ "�����"
procedure TForm1.Button2Click(Sender: TObject);
begin
  pas_list.Free;
  halt;
end;
//�������� � memo ���������� .pas ����� �������
procedure TForm1.ComboBox1Change(Sender: TObject);//
begin
  file_path:= proj_dir + Combobox1.Text;
  Memo1.Lines.LoadFromFile(file_path);
  memo1.ScrollBars:=ssVertical;
end;
//������ "���������" ��� ��������� � ���� �����
procedure TForm1.Button3Click(Sender: TObject);
begin
  Memo1.lines.savetofile(file_path);
end;
//������ "��������� ���" ��� ��������� � memo �����
procedure TForm1.Button4Click(Sender: TObject);
begin
  SaveDialog1.Filter:='����� ���� (*.pas)|*.pas'; //������ �� pas ������
  SaveDialog1.DefaultExt:='pas';//���������� �� ��������� ��� ���������� .pas
  with SaveDialog1, Memo1 do
    if Execute then Lines.SaveToFile(FileName);
end; //
//���� ������ ����. � �����, ���=1,����=4 (��-�� spinedit)
procedure TForm1.SpinEdit1Change(Sender: TObject);
begin
  mode:=SpinEdit1.Value;
end;
//������� ������� "Memo1" � ��. ��� ������� �����,�������������� tstringlist'�
procedure TForm1.FormActivate(Sender: TObject);
begin
  //��������� ��� ���������� ��������������
  types[1]:='integer'; types[2]:='cardinal'; types[3]:='shortint'; types[4]:='smallint';
  types[5]:='int64'; types[6]:='byte'; types[7]:='word'; types[8]:='real';
  types[9]:='longint'; types[10]:='single'; types[11]:='double'; types[12]:='extended';
  types[13]:='comp'; types[14]:='currency'; types[15]:='char'; types[16]:='boolean';
  types[17]:='bytebool'; types[18]:='wordbool'; types[19]:='longbool';
  types[20]:='array';
  types_weight[1]:=4; types_weight[2]:=4; types_weight[3]:=1; types_weight[4]:=2;
  types_weight[5]:=8; types_weight[6]:=1; types_weight[7]:=2; types_weight[8]:=6;
  types_weight[9]:=4; types_weight[10]:=4; types_weight[11]:=8; types_weight[12]:=10;
  types_weight[13]:=8; types_weight[14]:=8; types_weight[15]:=1; types_weight[16]:=1;
  types_weight[17]:=1; types_weight[18]:=2; types_weight[19]:=4; types_weight[20]:=0;
  memo1.lines.clear;
  combobox1.Clear;
  pas_list:=TStringList.Create;//������ ���� ���,�.�. �������� ����� �� ������� �����
end;
//������ "����� 1"
procedure TForm1.Button5Click(Sender: TObject);
begin
  if check_ready then//���� ������ ������
    begin
      make_out;
      MessageDlg('����� ������ �������.',mtInformation, [mbOk], 0);
    end
  else
    begin
      MessageDlg('������� �������� ������ � ��������� ������!',mtError, [mbOk], 0);
    end;
end;
//������������ TStringList
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  pas_list.Free;
end;
//������ "����� 2"
procedure TForm1.Button6Click(Sender: TObject);
var
  f:textfile;
begin
  if check_ready then//���� ������ ������
    begin
      assignfile(f,proj_dir+'\�����_2.csv');
      rewrite(f);
      writeln(f,',�����,� ����������� �.,� ������������� �.,��� �.');
      writeln(f,'���-�� �������,'+inttostr(funcs.all_numb)+','+inttostr(funcs.comm_gram)+
      ','+inttostr(funcs.comm_nogram)+','+inttostr(funcs.no_comm));

      writeln(f,'���-�� ������,'+inttostr(cyc.all_numb)+','+inttostr(cyc.comm_gram)+
      ','+inttostr(cyc.comm_nogram)+','+inttostr(cyc.no_comm));

      writeln(f,'���-�� �������,'+inttostr(cond.all_numb)+','+inttostr(cond.comm_gram)+
      ','+inttostr(cond.comm_nogram)+','+inttostr(cond.no_comm));

      writeln(f,'���-�� ����������,'+inttostr(tags.all_numb)+','+inttostr(tags.comm_gram)+
      ','+inttostr(tags.comm_nogram)+','+inttostr(tags.no_comm));

      writeln(f,'���-�� �����������,'+inttostr(constrs.all_numb)+','+inttostr(constrs.comm_gram)+
      ','+inttostr(constrs.comm_nogram)+','+inttostr(constrs.no_comm));

      writeln(f,'����� ���-��,'+inttostr(summ.all_numb)+','+inttostr(summ.comm_gram)+
      ','+inttostr(summ.comm_nogram)+','+inttostr(summ.no_comm));
      closefile(f);
      MessageDlg('����� ������ �������.',mtInformation, [mbOk], 0);
    end
  else
    begin
      MessageDlg('������� �������� ������ � ��������� ������!',mtError, [mbOk], 0);
    end;
end;
procedure ini();
var
  i:integer;
begin
  av_res:=0;
  summ.no_comm:=0;  funcs.no_comm:=0; cyc.no_comm:=0; cond.no_comm:=0;  constrs.no_comm:=0; tags.no_comm:=0;
  summ.comm_gram:=0;  funcs.comm_gram:=0; cyc.comm_gram:=0; cond.comm_gram:=0;  constrs.comm_gram:=0; tags.comm_gram:=0;
  summ.comm_nogram:=0;  funcs.comm_nogram:=0; cyc.comm_nogram:=0; cond.comm_nogram:=0;  constrs.comm_nogram:=0; tags.comm_nogram:=0;
  summ.all_numb:=0;  funcs.all_numb:=0; cyc.all_numb:=0; cond.all_numb:=0;  constrs.all_numb:=0; tags.all_numb:=0;
  for i:=1 to 20 do
    types_amount[i]:=0;
  end;
//������ "������"
procedure TForm1.Button7Click(Sender: TObject);
begin
  if pas_list.Count>0 then//���� ������ ������
    begin
      ini();
      mode:=SpinEdit1.Value;//� ������� spinedit.change �� ����������� ��������� �������� � mode
      non_clear();
      analyz_all();
      summary();
      check_ready:=true//���� ����,��� ������ ��������
    end
  else
    begin
      if pas_list.Count>0 then
      MessageDlg('������� �������� ������!',mtError, [mbOk], 0)
      else MessageDlg('���� ������� ���� ��� �������� ��������� (������ ���� UTF-8)!',mtError, [mbOk], 0);
    end;
end;
//������ "����� �������"
procedure TForm1.Button1Click(Sender: TObject);
var
  selectedFile: string;
  tmp:string;
  dlg: TOpenDialog;
  f:TextFile;
  i:integer;
begin
  selectedFile := '';
  dlg := TOpenDialog.Create(nil);
  try
    //dlg.InitialDir := ':\';
    dlg.Filter := '����� ������� Delphi (*.dpr)|*.dpr'; //������ �� dpr ������
    if dlg.Execute() then //���� ������� ���� ������ �������
      selectedFile := dlg.FileName;
  finally
    dlg.Free;
  end;
  if selectedFile <> '' then //���� ������� ����
  //���������� �� ����� dpl �������� ������
    begin
      check_ready:=false;//����� ����� ������������ ������� ������� ��� ������ ������
      MessageDlg('File : '+selectedFile,mtInformation,[mbOk],0);
      proj_dir:=ExtractFilePath(selectedFile);//��������� ���� � ������� ��� ������������ pas ������
      AssignFile(f,selectedFile);
      Reset(f);
      if IOResult<>0 then
        begin
          MessageDlg('������ ������� � ����� '+selectedFile,mtError, [mbOk], 0);
          exit;
        end;
      pas_list.LoadFromFile(selectedFile);
      Form1.Caption:=selectedFile;
      for i:=pas_list.Count-1 downto 0 do
        begin
          if pos(' in ',pas_list[i])=0 then pas_list.Delete(i)
          else
            begin
              tmp:=pas_list.strings[i];
              delete(tmp,1,pos(' in ',tmp)+4);
              delete(tmp,pos('pas',tmp)+3,length(tmp));
              if FileExists(proj_dir+tmp)=true then
              begin
                pas_list.strings[i]:=tmp;
                combobox1.Items.Add(pas_list.strings[i])
              end
              else
              begin
                pas_list.Delete(i);
                MessageDlg('� ����� ������� ������ �������������� ����: '+tmp,mtError,[mbOk],0);
              end;
          end;
        end;
      pas_list.Savetofile(proj_dir+'\������ pas ������.txt')
    end
    else MessageDlg('����� ����� ��� �������',mtError,[mbOk],0);
end;
{**********************************************************************}
{*****************���������� ���������/�������*************************}
{*****����� ����������� ������ ����������� � ����������� �� ������*****}
//����������� ������
{procedure mode_1(const file_line:TStringList;var p:integer; const k:integer; var constr:Tconstruction);//
var
g,line:string;
tmp:integer;
begin
  line:=file_line.Strings[k];
  tmp:=pos('//',line);
  if tmp<>0 then
  begin
    g:=copy(line,tmp+2,length(line)(*-(tmp+1)*));//�� ����, ��� ��������, �� � ��� ���� ��������
    //ShowMessage(g);
    if grammatic(g)=true then
      constr.comm_gram:=constr.comm_gram+1
    else
      constr.comm_nogram:=constr.comm_nogram+1;
    //����� ����� �������� �� �����. ������������
  end
  else//���� ����������� ���
  begin
    constr.no_comm:=constr.no_comm+1;
    non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
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
  flag:=true;//���� �������������� ����������� ������������� �����������
  tmp:=pos('//',file_line.strings[k-1]);
  line:=file_line.strings[k-1];
  if (tmp<>0) then
    begin
       g:=copy(line,tmp+2,length(line));
      for i:=tmp-1 downto 1 do//��������, �� ���������� ������� ������ �����������
                              //����� �� ��������� �����, ��������� � ����������� � ���������� �������
        begin
          if line[i]<>' ' then begin flag:=false; break; end;
        end;
        if flag=true then
           //ShowMessage(g);
          if grammatic(g)=true then
            constr.comm_gram:=constr.comm_gram+1
          else
            constr.comm_nogram:=constr.comm_nogram+1
        else
        begin
          constr.no_comm:=constr.no_comm+1;
          non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
          p:=p+1;//������� ������� � �������� ���������. �����
        end;
    //����� ����� �������� �� �����. ������������
    end
    else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
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
  flag:=true;//���� �������������� ����������� ������������� �����������
  tmp:=pos('//',file_line.strings[k+1]);
  line:=file_line.strings[k+1];
  if (tmp<>0) then
    begin
      g:=copy(line,tmp+2,length(line));
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
          non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
          p:=p+1;//������� ������� � �������� ���������. �����
        end;
    end
    else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
      p:=p+1;//������� ������� � �������� ���������. �����
    end;
end;
//����������� ������ � ������    � �����
procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp,tmp2,tmp3:integer;
  line,line2,line3,g:string;
begin
  flag:=true;//���� �������������� ����������� ������������� �����������
  line:=file_line.strings[k-1];
  line3:=file_line.strings[k+1];
  line2:=file_line.strings[k];
  tmp:=pos('//',line);
  tmp2:=pos('//',line2);
  tmp3:=pos('//',line3);
  if (tmp<>0) or (tmp2<>0) or (tmp3<>0) then
    begin
      if tmp<>0 then
        begin
          g:=copy(line,tmp+2,length(line));
          for i:=tmp-1 downto 1 do
            begin
              if line[i]<>' ' then begin flag:=false; break; end;
            end;
          //����� ����� �������� �� �����. ������������
        end;
      if tmp3<>0 then
          begin
            g:=copy(line3,tmp3+2,length(line3));
            for i:=tmp3-1 downto 1 do//��������,��� �� ���������� ������� ������ �����������. � ��������� ������ ��,
                              //��������� �����, ��������� � ����������� � ���������� �������
            begin
             if line3[i]<>' ' then begin flag:=false; break; end;
            end;
            //����� ����� �������� �� �����. ������������
          end;

      if tmp2<>0 then
        begin
          g:=copy(line2,tmp2+2,length(line2) );
          flag:=true;
        end;
    end
    else
    //begin
    flag:=false;
    //end;
    if flag=true then
      if grammatic(g)=true then
        constr.comm_gram:=constr.comm_gram+1
      else
        constr.comm_nogram:=constr.comm_nogram+1
    else
    begin
        constr.no_comm:=constr.no_comm+1;
        non[p]:=inttostr(k+1);//� ������ ��������� � 0-> (k+1)
        p:=p+1;//������� ������� � �������� ���������. �����
    end;
end;   }
{**********************************************************************}
procedure make_mark(var x1:integer; var x2:integer; var caption:byte);
begin
  if (10*x1<=2*x2) then if caption=1 then Form1.lblAmount.Caption:='1/5'
                                        else Form1.lblGram.Caption:='1/5';

  if (10*x1<=4*x2) and (10*x1>=2*x2)
                   then if caption=1 then Form1.lblAmount.Caption:='2/5'
                                        else Form1.lblGram.Caption:='2/5';

  if (10*x1<=6*x2) and
     (10*x1>=4*x2) then if caption=1 then Form1.lblAmount.Caption:='3/5'
                                        else Form1.lblGram.Caption:='3/5';

  if (10*x1<=8*x2) and (10*x1>=6*x2)
                   then if caption=1 then Form1.lblAmount.Caption:='4/5'
                                        else Form1.lblGram.Caption:='4/5';

  if (10*x1>=8*x2) then if caption=1 then Form1.lblAmount.Caption:='5/5'
                                        else Form1.lblGram.Caption:='5/5';
end;
//���������� � ������ ������ �������������� ������� �� ����������
procedure make_mark_amount();
var
tmp:integer;
b:byte;
begin
  b:=1;
  tmp:= summ.all_numb-summ.no_comm;
  make_mark(tmp,summ.all_numb,b);
 end;
//���������� � ������ ������ �������������� ������� �� �����������
procedure make_mark_gram();
var
tmp:integer;
b:byte;
begin
  b:=0;
  tmp:= summ.all_numb-summ.no_comm;
  make_mark(summ.comm_gram,tmp,b);
 end;
//���������� ��������������
procedure resurs(const pas_open:TStringList; const k:integer);
var
  i,i_5,i_6,tmp,tmp2,tmp3,tmp4,g,dots:integer;
  flag:boolean;
  line,arr_val:String;
begin
  dots:=1;//����� ���������� ������� ����, ������� ��� ����� ���������� ���������� ����� �������
  line:=Lowercase(pas_open.Strings[k]);
  for i:=1 to 19 do
    begin
    flag:=true;
      tmp:=pos(types[i],line);
      if (tmp<>0) and (pos('function',line)=0) and (pos('procedure',line)=0) then
        begin
           if tmp>1 then//���� �������� ����� ������� �� � ������ ������, ��||||������ ������� ����� ������� ���������� ��������, �.�. ����� ���� �� ��������� �����
            if (line[tmp-1]<>' ') and (line[tmp-1]<>':') and (pos('array',line)<>0) then//���������,����� �� ���� ��� ������, ����� ���� � 0
              flag:=false;
           try
            if (line[tmp+length(types[i])]<>' ') and (line[tmp+length(types[i])]<>';') then//���������,����� ����� ���� ��� ������, ����� ���� � 0
              flag:=false;
             //���� try-except ��� ������, ������ ��� ������-�� �������� ������ � msword
          except
           // ShowMessage(line);
            end;
           if (flag=true) then //������� ������� (����� ����������� ����������)
            begin
              for i_6:=1 to length(line) do
                if line[i_6] = ',' then inc(dots);
              types_amount[i]:=types_amount[i]+dots;
            end;
        end;
    end;
  //���������� � ���������� �������������� �� ��������
  tmp2:=pos(types[20],line);
  if (tmp2<>0) then
    begin
      tmp3:=pos(']',line);
      tmp4:=pos('..',line)+2;
      if (tmp3<>0) and (tmp4-2<>0) then
        begin
          arr_val:=copy(line,tmp4,tmp3-tmp4);
          try
            g:=StrToInt(arr_val);//�����������
            for i_5:=1 to 19 do
            begin
              if (pos(types[i_5],line)<>0) then
                types_amount[20]:=types_amount[20]+g*types_weight[i_5];
            end;
          except//���� ����������� ������ ��������
          end;

        end;
    end;
end;
//���������� �������������� �� ��������
procedure count_arr();
var
i_3:integer;
sum:longint;
begin
  sum:=0;
  for i_3:=1 to 19 do
    begin
      types_amount[i_3]:=types_amount[i_3]*types_weight[i_3];
      sum:=sum+types_amount[i_3];

    end;
  av_res:=av_res+sum;
  av_res:=av_res+types_amount[20];
end;
//�������� �� �������������� ������������
{function grammatic(var comment:String):boolean;
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
end;  }
//������� ������ ����� ����������� ������� � �������� ��� ����.������ setlength(non,1000)-�����,�� ���� �� ��������,��� ��-�������.
{procedure non_clear();
var
  i:integer;
begin
  setlength(non,1000);
  for i:=0 to length(non)-1 do
    non[i]:='';
end; }
{****************�������� ������� ��������� �����������****************}
//����� ������ ���������������
procedure choose_mode(const pas_open:TStringList; var p:integer; const k:integer;var variab:Tconstruction);
begin
  variab.all_numb:=variab.all_numb+1;
  case mode of
    1:mode_1(pas_open,p,k,variab);
    2:mode_2(pas_open,p,k,variab);
    3:mode_3(pas_open,p,k,variab);
    4:mode_4(pas_open,p,k,variab);
  end;
end;
//����� ������� ������ ����������� diff � ����
procedure analys_common(const pas_open:TStringList; var p:integer; const k:integer;const diff:string);
var
  line:string;
  tmp:integer;
  flag,flag2:boolean;
begin
  flag:=true;//���� ������� ������� �� ��������� �����
  flag2:=true;//���� ������� ������� ����� ��������� �����
  line:=Lowercase(pas_open.Strings[k]);
  //if pos('class procedure Setu',line)<>0 then ShowMessage('nashli');
  if (pos(diff,line)<>0)then
    begin
      tmp:=pos(diff,line);
      if tmp>1 then//���� �������� ����� ������� �� � ������ ������, ��
        if line[tmp-1]<>' ' then//���������,����� �� ���� ��� ������, ����� ���� � 0
          flag:=false;
      if (tmp+length(diff))<length(line) then//���� ����� ��������� ����� � ������ ���� �����-�� ������
        if (line[tmp+length(diff)] <> ' ') then//�� ���������,����� ��� ��� ������, ����� ���� � 0
          flag2:=false;
      //������ ��� ������� - ���������� �������� �������� "������" ��������� �����.�� �����,����� �������� �� ��� � �����������.

      if (flag = true)  and  (flag2=true) { or (Length(line)=(tmp+length(diff))))} then//����� � ��� ���� ��������,������ �� ���� � 3 �������
        begin

        //����� ��������� ��������� ���� ������ ���������� ����������� ���� ��� ����� ���� ���������� ������ choose_mode,
        //��������� � ������� ������. (25.10.2016)
          if (diff='procedure') or (diff='function') then choose_mode(pas_open,p,k,funcs);//������ �� ���������/�������
          if (diff='if') or (diff='case') then choose_mode(pas_open,p,k,cond);//������ �� �������
          if (diff='for') or (diff='while') or (diff='repeat') then choose_mode(pas_open,p,k,cyc);//������ �� �����
          if (diff='type') or (diff='try') then choose_mode(pas_open,p,k,constrs);//������ �� �����������
        end;
    end;
end;
//������ ������� ���� �� ���������� ����� var-begin/implementation
procedure tags_an_var(const pas_open:TStringList; var p:integer; const k:integer);
var
  line:string;
  temp_k:integer;
  tmp,i:integer;
  flag:boolean;
begin
  line:=Lowercase(pas_open.Strings[k]);
  flag:=true;
  if (pos('var',line)<>0) then
    begin
      tmp:=pos('var',line);
      for i:=tmp-1 downto 1 do//����� -1, ����� �� ����������� ���� �������� �����
      begin
        if line[i]<>' ' then
          begin
            flag:=false;
            break;
          end;
      end;
      //������ �������-���� ����� ����� ���-�� ����, ������-��� ����� var ��� ��� ������ �������,������-��� � ������ ����� var ������ ���
      //��� �������� ����������� ���������� ���������� ��������
      if (flag=true) and ((line[tmp+1]=' ') or ( (length(line)-pos('//',line) )=(tmp+2))) then
      begin
        temp_k:=k+1;
        repeat
          if (pos(':',pas_open.Strings[temp_k])<>0) and (pos('procedure',pas_open.Strings[temp_k])=0)
                  and (pos('function',pas_open.Strings[temp_k])=0)then
            begin
              tags.all_numb:=tags.all_numb+1;
              case mode of
                1:mode_1(pas_open,p,temp_k,tags);
                2:mode_2(pas_open,p,temp_k,tags);
                3:mode_3(pas_open,p,temp_k,tags);
                4:mode_4(pas_open,p,temp_k,tags);
              end;
            end;
          temp_k:=temp_k+1;
        until (pos('begin',Lowercase(pas_open.Strings[temp_k]))<>0) or (pos('implementation',Lowercase(pas_open.Strings[temp_k]))<>0);
      end;
    end;
end;
{**********************************************************************}
{*********����������� ������ ������� ������� ���� �����������**********}
//������ �������
procedure analyz_all();
var
  curr_file:string;//����,�������������� �� i-� ��������
  i,k,p:integer;
begin
  p:=0;
//try
  for i:=0 to pas_list.Count-1 do//������ � pas �������
    begin
      curr_file:=proj_dir+pas_list.strings[i];
      non[p]:=pas_list.Strings[i];
      p:=p+1;
      pas_open:=TStringList.Create;
      pas_open.LoadFromFile(curr_file);
      for k:=0 to pas_open.Count-1 do//���������� ������ pas �����.k-������
        begin
          //����� �������,������������� ��������� �����������
          analys_common(pas_open,p,k,'procedure');
          analys_common(pas_open,p,k,'function');
          analys_common(pas_open,p,k,'for');
          analys_common(pas_open,p,k,'while');
          analys_common(pas_open,p,k,'repeat');
          analys_common(pas_open,p,k,'if');
          analys_common(pas_open,p,k,'case');
          analys_common(pas_open,p,k,'type');
          analys_common(pas_open,p,k,'try');
          tags_an_var(pas_open,p,k);
          resurs(pas_open,k);
        end;
      MessageDlg('������ ����� '+pas_list.strings[i]+' ��������. '+
                    inttostr(pas_open.Count)+' �����.',mtInformation,[mbYes],0);
      pas_open.Free;//�������� �� ������ ������,����������� ������������� ����
  end;
  count_arr();//������� ��������������
//except
 // MessageDlg('������ ����� �������������� ������!',mtError,[mbOK],0);
//end;
end;
//������������ ����� ���� �����������(+� ����.,��� ����. � �.�.)
procedure summary();
begin
  summ.no_comm    :=funcs.no_comm     +cyc.no_comm    +cond.no_comm     +tags.no_comm     +constrs.no_comm;
  summ.comm_gram  :=funcs.comm_gram   +cyc.comm_gram  +cond.comm_gram   +tags.comm_gram   +constrs.comm_gram;
  summ.comm_nogram:=funcs.comm_nogram +cyc.comm_nogram+cond.comm_nogram +tags.comm_nogram +constrs.comm_nogram;
  summ.all_numb   :=funcs.all_numb    +cyc.all_numb   +cond.all_numb    +tags.all_numb    +constrs.all_numb;
  make_mark_amount();
  make_mark_gram();
end;
//������� ����� ������ .txt
procedure make_out();
var
  k:integer;
  f:textfile;
begin
  k:=0;
  assignfile(f,proj_dir+'\�����_1.txt');
  rewrite(f);
  writeln(f,'��������������: ',av_res,' ����.');
  writeln(f,'������ ����� ��� ������������: ');
  while k<=length(non)-1 do
    begin
      writeln(f,non[k]);
      k:=k+1;

    end;
  closefile(f);
end;
{**********************************************************************}
end.

