unit main;
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin,ComObj,Checking_unit;
//тип для конструкций:непрокомм.,грамм.прав.комм.,грамм.непр.,общее число комм.строк
{type//тип для конструкций:непрокомм.,грамм.прав.комм.,грамм.непр.,общее число комм.строк
  Tconstruction = record
    no_comm, comm_gram, comm_nogram, all_numb:integer;
end;   }
//описание элементов формы
type
  TForm1 = class(TForm)
    Button1: TButton;//открыть проект
    Button2: TButton;//выход
    Label1: TLabel;
    ComboBox1: TComboBox;//выбор файла
    Button3: TButton;//сохранить
    Button4: TButton;//сохранить как
    SaveDialog1: TSaveDialog;
    Label2: TLabel;//режим комментирования
    Memo1: TMemo;//поле для вывода файла
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
    procedure Button1Click(Sender: TObject);//открыть проект
    procedure Button2Click(Sender: TObject);//выход
    procedure ComboBox1Change(Sender: TObject);//выбор файла в проекте для просмотра/изменения
    procedure Button3Click(Sender: TObject);//сохранить
    procedure Button4Click(Sender: TObject);//сохранить как
    procedure SpinEdit1Change(Sender: TObject);//выбор режима комментирования
    procedure FormActivate(Sender: TObject);//активация формы
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);//закрытие формы
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;//
  types:array[1..20] of string;
  av_res:longint;//   ресурсоемкость
  types_amount:array[1..20] of integer;//ниправильный каминтарий
  types_weight:array[1..20] of integer;
  check_ready:boolean;//флаг для проверки проведенного анализа
  pas_list: TStringList;//список для обработки .dpr. После обработки хранит файлы .pas
  proj_dir:string;//path выбранного проекта
  file_path:string;//путь к файлу для открытия в memo
  mode:byte;//режим комментирования
  funcs,cyc,cond,tags,constrs,summ:Tconstruction;//данные о коммнетариях к конструкциям в проекте
  pas_open:TStringList;//хранит анализируемые на каждой итерации файлы
  //non:array of string;//(имя файла+номера строк без комментариев) для всего проекта
  //function grammatic(var comment:String):boolean;//проверка комментария на грамматику
  procedure resurs(const pas_open:TStringList; const k:integer);//вычисление ресурсоемкости (общее)
  procedure count_arr();//подсчет ресурсоемкости по массивам
  //поиск комментария в соответствии с режимом
 { procedure mode_1(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. справа
  procedure mode_2(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. сверху
  procedure mode_3(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. снизу
  procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);//к. справа и сверху
  }procedure choose_mode(const pas_open:TStringList; var p:integer; const k:integer;var variab:Tconstruction);//выбор режима комментирования+подсчет общего числа той или иной конструкции
  procedure analys_common(const pas_open:TStringList; var p:integer; const k:integer;const diff:string);//поиск конструкций diff в коде
  procedure tags_an_var(const pas_open:TStringList; var p:integer; const k:integer);//анализ на переменные
  //формирование файла с отчетом 1
  procedure make_out();
  procedure ini();
  //анализ проекта
  procedure analyz_all();
  //суммирование числа всех конструкций(+с комм.,без комм. и т.д.)
  procedure summary();
  //очистка строки перед заполнением данными о строчках без комм.
  //procedure non_clear();
  procedure make_mark_amount();
  procedure make_mark_gram();



implementation

uses Math;

{$R *.dfm}
{*******************АКТИВНЫЕ ЭЛЕМЕНТЫ ФОРМЫ****************************}
//кнопка "ВЫХОД"
procedure TForm1.Button2Click(Sender: TObject);
begin
  pas_list.Free;
  halt;
end;
//открытие в memo выбранного .pas файла проекта
procedure TForm1.ComboBox1Change(Sender: TObject);//
begin
  file_path:= proj_dir + Combobox1.Text;
  Memo1.Lines.LoadFromFile(file_path);
  memo1.ScrollBars:=ssVertical;
end;
//кнопка "СОХРАНИТЬ" для открытого в мемо файла
procedure TForm1.Button3Click(Sender: TObject);
begin
  Memo1.lines.savetofile(file_path);
end;
//кнопка "СОХРАНИТЬ КАК" для открытого в memo файла
procedure TForm1.Button4Click(Sender: TObject);
begin
  SaveDialog1.Filter:='Файлы кода (*.pas)|*.pas'; //фильтр по pas файлам
  SaveDialog1.DefaultExt:='pas';//расширение по умолчанию для сохранения .pas
  with SaveDialog1, Memo1 do
    if Execute then Lines.SaveToFile(FileName);
end; //
//ввод режима комм. с формы, мин=1,макс=4 (св-ва spinedit)
procedure TForm1.SpinEdit1Change(Sender: TObject);
begin
  mode:=SpinEdit1.Value;
end;
//стираем надписи "Memo1" и пр. при запуске формы,инициализируем tstringlist'ы
procedure TForm1.FormActivate(Sender: TObject);
begin
  //заготовка для вычисления ресурсоемкости
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
  pas_list:=TStringList.Create;//должно быть тут,т.к. проверки стоят по размеру листа
end;
//кнопка "ОТЧЕТ 1"
procedure TForm1.Button5Click(Sender: TObject);
begin
  if check_ready then//если проект выбран
    begin
      make_out;
      MessageDlg('Отчет создан успешно.',mtInformation, [mbOk], 0);
    end
  else
    begin
      MessageDlg('Сначала выберите проект и выполните анализ!',mtError, [mbOk], 0);
    end;
end;
//освобождение TStringList
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  pas_list.Free;
end;
//кнопка "ОТЧЕТ 2"
procedure TForm1.Button6Click(Sender: TObject);
var
  f:textfile;
begin
  if check_ready then//если проект выбран
    begin
      assignfile(f,proj_dir+'\Отчет_2.csv');
      rewrite(f);
      writeln(f,',Общее,С правильными к.,С неправильными к.,Без к.');
      writeln(f,'Кол-во Функций,'+inttostr(funcs.all_numb)+','+inttostr(funcs.comm_gram)+
      ','+inttostr(funcs.comm_nogram)+','+inttostr(funcs.no_comm));

      writeln(f,'Кол-во циклов,'+inttostr(cyc.all_numb)+','+inttostr(cyc.comm_gram)+
      ','+inttostr(cyc.comm_nogram)+','+inttostr(cyc.no_comm));

      writeln(f,'Кол-во условий,'+inttostr(cond.all_numb)+','+inttostr(cond.comm_gram)+
      ','+inttostr(cond.comm_nogram)+','+inttostr(cond.no_comm));

      writeln(f,'Кол-во переменных,'+inttostr(tags.all_numb)+','+inttostr(tags.comm_gram)+
      ','+inttostr(tags.comm_nogram)+','+inttostr(tags.no_comm));

      writeln(f,'Кол-во конструкций,'+inttostr(constrs.all_numb)+','+inttostr(constrs.comm_gram)+
      ','+inttostr(constrs.comm_nogram)+','+inttostr(constrs.no_comm));

      writeln(f,'Общее кол-во,'+inttostr(summ.all_numb)+','+inttostr(summ.comm_gram)+
      ','+inttostr(summ.comm_nogram)+','+inttostr(summ.no_comm));
      closefile(f);
      MessageDlg('Отчет создан успешно.',mtInformation, [mbOk], 0);
    end
  else
    begin
      MessageDlg('Сначала выберите проект и выполните анализ!',mtError, [mbOk], 0);
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
//Кнопка "АНАЛИЗ"
procedure TForm1.Button7Click(Sender: TObject);
begin
  if pas_list.Count>0 then//если проект выбран
    begin
      ini();
      mode:=SpinEdit1.Value;//в событии spinedit.change не сохраняется начальное значение в mode
      non_clear();
      analyz_all();
      summary();
      check_ready:=true//флаг того,что анализ проведен
    end
  else
    begin
      if pas_list.Count>0 then
      MessageDlg('Сначала выберите проект!',mtError, [mbOk], 0)
      else MessageDlg('Файл проекта пуст или неверная кодировка (должна быть UTF-8)!',mtError, [mbOk], 0);
    end;
end;
//Кнопка "ВЫБОР ПРОЕКТА"
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
    dlg.Filter := 'Файлы проекта Delphi (*.dpr)|*.dpr'; //фильтр по dpr файлам
    if dlg.Execute() then //если вызвано окно выбора проекта
      selectedFile := dlg.FileName;
  finally
    dlg.Free;
  end;
  if selectedFile <> '' then //если считали файл
  //считывание из файла dpl названия файлов
    begin
      check_ready:=false;//сброс флага выполненного анализа проекта при выборе нового
      MessageDlg('File : '+selectedFile,mtInformation,[mbOk],0);
      proj_dir:=ExtractFilePath(selectedFile);//сохраняем путь к проекту для вытаскивания pas файлов
      AssignFile(f,selectedFile);
      Reset(f);
      if IOResult<>0 then
        begin
          MessageDlg('Ошибка доступа к файлу '+selectedFile,mtError, [mbOk], 0);
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
                MessageDlg('В файле проекта указан несуществующий файл: '+tmp,mtError,[mbOk],0);
              end;
          end;
        end;
      pas_list.Savetofile(proj_dir+'\Список pas файлов.txt')
    end
    else MessageDlg('Выбор файла был отменен',mtError,[mbOk],0);
end;
{**********************************************************************}
{*****************НАПИСАННЫЕ ПРОЦЕДУРЫ/ФУНКЦИИ*************************}
{*****ПОИСК КОММЕНТАРИЯ ВОКРУГ КОНСТРУКЦИИ В ЗАВИСИМОСТИ ОТ РЕЖИМА*****}
//комментарии справа
{procedure mode_1(const file_line:TStringList;var p:integer; const k:integer; var constr:Tconstruction);//
var
g,line:string;
tmp:integer;
begin
  line:=file_line.Strings[k];
  tmp:=pos('//',line);
  if tmp<>0 then
  begin
    g:=copy(line,tmp+2,length(line)(*-(tmp+1)*));//по идее, это уточняет, но и без него работает
    //ShowMessage(g);
    if grammatic(g)=true then
      constr.comm_gram:=constr.comm_gram+1
    else
      constr.comm_nogram:=constr.comm_nogram+1;
    //здесь будет проверка на грамм. правильность
  end
  else//если комментария нет
  begin
    constr.no_comm:=constr.no_comm+1;
    non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
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
  flag:=true;//флаг принадлежности комментария анализируемой конструкции
  tmp:=pos('//',file_line.strings[k-1]);
  line:=file_line.strings[k-1];
  if (tmp<>0) then
    begin
       g:=copy(line,tmp+2,length(line));
      for i:=tmp-1 downto 1 do//проверка, на предыдущей строчке только комментарий
                              //иначе он вероятнее всего, относится к конструкции с предыдущей строчки
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
          non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
          p:=p+1;//счетчик массива с номерами непрокомм. строк
        end;
    //здесь будет проверка на грамм. правильность
    end
    else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
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
  flag:=true;//флаг принадлежности комментария анализируемой конструкции
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
          non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
          p:=p+1;//счетчик массива с номерами непрокомм. строк
        end;
    end
    else
    begin
      constr.no_comm:=constr.no_comm+1;
      non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
      p:=p+1;//счетчик массива с номерами непрокомм. строк
    end;
end;
//комментарии сверху и справа    и снизу
procedure mode_4(const file_line:TStringList;var p:integer; const k:integer;var constr:Tconstruction);
var
  flag:boolean;
  i,tmp,tmp2,tmp3:integer;
  line,line2,line3,g:string;
begin
  flag:=true;//флаг принадлежности комментария анализируемой конструкции
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
          //здесь будет проверка на грамм. правильность
        end;
      if tmp3<>0 then
          begin
            g:=copy(line3,tmp3+2,length(line3));
            for i:=tmp3-1 downto 1 do//проверка,что на предыдущей строчке только комментарий. в противном случае он,
                              //вероятнее всего, относится к конструкции с предыдущей строчки
            begin
             if line3[i]<>' ' then begin flag:=false; break; end;
            end;
            //здесь будет проверка на грамм. правильность
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
        non[p]:=inttostr(k+1);//в списке нумерация с 0-> (k+1)
        p:=p+1;//счетчик массива с номерами непрокомм. строк
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
//вычисление и выдача оценки анализируемого проекта по количеству
procedure make_mark_amount();
var
tmp:integer;
b:byte;
begin
  b:=1;
  tmp:= summ.all_numb-summ.no_comm;
  make_mark(tmp,summ.all_numb,b);
 end;
//вычисление и выдача оценки анализируемого проекта по грамотности
procedure make_mark_gram();
var
tmp:integer;
b:byte;
begin
  b:=0;
  tmp:= summ.all_numb-summ.no_comm;
  make_mark(summ.comm_gram,tmp,b);
 end;
//вычисление ресурсоемкости
procedure resurs(const pas_open:TStringList; const k:integer);
var
  i,i_5,i_6,tmp,tmp2,tmp3,tmp4,g,dots:integer;
  flag:boolean;
  line,arr_val:String;
begin
  dots:=1;//число переменных однонго типа, введено для учета объявления переменных через запятую
  line:=Lowercase(pas_open.Strings[k]);
  for i:=1 to 19 do
    begin
    flag:=true;
      tmp:=pos(types[i],line);
      if (tmp<>0) and (pos('function',line)=0) and (pos('procedure',line)=0) then
        begin
           if tmp>1 then//если ключевое слово пишется не с начала строки, то||||третье условие чтобы отсеять объявления массивов, т.к. поиск идет по названиям типов
            if (line[tmp-1]<>' ') and (line[tmp-1]<>':') and (pos('array',line)<>0) then//проверяем,чтобы до него был пробел, иначе флаг в 0
              flag:=false;
           try
            if (line[tmp+length(types[i])]<>' ') and (line[tmp+length(types[i])]<>';') then//проверяем,чтобы после него был пробел, иначе флаг в 0
              flag:=false;
             //этот try-except был сделан, потому что почему-то попадали строки с msword
          except
           // ShowMessage(line);
            end;
           if (flag=true) then //подсчет запятых (числа объявляемых переменных)
            begin
              for i_6:=1 to length(line) do
                if line[i_6] = ',' then inc(dots);
              types_amount[i]:=types_amount[i]+dots;
            end;
        end;
    end;
  //подготовка к вычислению ресурсоемкости по массивам
  tmp2:=pos(types[20],line);
  if (tmp2<>0) then
    begin
      tmp3:=pos(']',line);
      tmp4:=pos('..',line)+2;
      if (tmp3<>0) and (tmp4-2<>0) then
        begin
          arr_val:=copy(line,tmp4,tmp3-tmp4);
          try
            g:=StrToInt(arr_val);//размерность
            for i_5:=1 to 19 do
            begin
              if (pos(types[i_5],line)<>0) then
                types_amount[20]:=types_amount[20]+g*types_weight[i_5];
            end;
          except//если размерность задана символом
          end;

        end;
    end;
end;
//вычисление ресурсоемкости по массивам
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
//проверка на грамматическую правильность
{function grammatic(var comment:String):boolean;
var
  WordDoc:OLEVariant;
  IsMSWordNew:Boolean;
  FWordApp:Variant;
begin
//подключиться к ворду, настроить его
  try
    FWordApp:=GetActiveOleObject('Word.Application');
    IsMSWordNew:=False;//признак того, что удалось подключиться к сущесвтующему экземпляру ворда
  except
    FWordApp:=CreateOleObject('Word.Application');
    FWordApp.Visible:=False;
    IsMSWordNew:=True;//признак, что ворд новый и его надо будет закрыть
  end;
  try//для гарантированного отключения от ворда
  //как было выяснено, для получения списка вариантов слов в ворде обязательно должен быть создан хоть один документ
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
end;  }
//очистка строки перед заполнением данными о строчках без комм.делать setlength(non,1000)-плохо,но пока не придумал,как по-другому.
{procedure non_clear();
var
  i:integer;
begin
  setlength(non,1000);
  for i:=0 to length(non)-1 do
    non[i]:='';
end; }
{****************АЛГОРИТМ АНАЛИЗА РАЗЛИЧНЫХ КОНСТРУКЦИЙ****************}
//выбор режима комментирования
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
//общая функция поиска конструкций diff в коде
procedure analys_common(const pas_open:TStringList; var p:integer; const k:integer;const diff:string);
var
  line:string;
  tmp:integer;
  flag,flag2:boolean;
begin
  flag:=true;//флаг пустого символа до ключевого слова
  flag2:=true;//флаг пустого символа после ключевого слова
  line:=Lowercase(pas_open.Strings[k]);
  //if pos('class procedure Setu',line)<>0 then ShowMessage('nashli');
  if (pos(diff,line)<>0)then
    begin
      tmp:=pos(diff,line);
      if tmp>1 then//если ключевое слово пишется не с начала строки, то
        if line[tmp-1]<>' ' then//проверяем,чтобы до него был пробел, иначе флаг в 0
          flag:=false;
      if (tmp+length(diff))<length(line) then//если после ключевого слова в строке есть какой-то символ
        if (line[tmp+length(diff)] <> ' ') then//то проверяем,чтобы это был пробел, иначе флаг в 0
          flag2:=false;
      //первые два условия - отсутствие значащих символов "вокруг" ключевого слова.не помню,зачем поставил то что в комментарии.

      if (flag = true)  and  (flag2=true) { or (Length(line)=(tmp+length(diff))))} then//вроде и без него работает,смысла не вижу в 3 условии
        begin

        //после последних изменений учет общего количества конструкции того или иного типа происходит внутри choose_mode,
        //совместно с выбором режима. (25.10.2016)
          if (diff='procedure') or (diff='function') then choose_mode(pas_open,p,k,funcs);//анализ на процедуры/функции
          if (diff='if') or (diff='case') then choose_mode(pas_open,p,k,cond);//анализ на условия
          if (diff='for') or (diff='while') or (diff='repeat') then choose_mode(pas_open,p,k,cyc);//анализ на циклы
          if (diff='type') or (diff='try') then choose_mode(pas_open,p,k,constrs);//анализ на конструкции
        end;
    end;
end;
//анализ строчки кода на переменные между var-begin/implementation
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
      for i:=tmp-1 downto 1 do//здесь -1, чтобы не учитывалось само ключевое слово
      begin
        if line[i]<>' ' then
          begin
            flag:=false;
            break;
          end;
      end;
      //первое условие-если перед варом что-то есть, второе-что после var нет еще одного символа,третье-что в строке кроме var ничего нет
      //это исключит определение формальных переменных процедур
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
{*********ОБЪЕДИНЕНИЕ ВЫЗОВА ФУНКЦИЙ АНАЛИЗА ВСЕХ КОНСТРУКЦИЙ**********}
//анализ проекта
procedure analyz_all();
var
  curr_file:string;//файл,обрабатываемый на i-й итерации
  i,k,p:integer;
begin
  p:=0;
//try
  for i:=0 to pas_list.Count-1 do//список с pas файлами
    begin
      curr_file:=proj_dir+pas_list.strings[i];
      non[p]:=pas_list.Strings[i];
      p:=p+1;
      pas_open:=TStringList.Create;
      pas_open.LoadFromFile(curr_file);
      for k:=0 to pas_open.Count-1 do//построчный анализ pas файла.k-строка
        begin
          //вызов функций,анализирующих различные конструкции
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
      MessageDlg('Анализ файла '+pas_list.strings[i]+' завершен. '+
                    inttostr(pas_open.Count)+' строк.',mtInformation,[mbYes],0);
      pas_open.Free;//удаление из памяти списка,содержащего анализируемый файл
  end;
  count_arr();//подсчет ресурсоемкости
//except
 // MessageDlg('Проект имеет синтаксические ошибки!',mtError,[mbOK],0);
//end;
end;
//суммирование числа всех конструкций(+с комм.,без комм. и т.д.)
procedure summary();
begin
  summ.no_comm    :=funcs.no_comm     +cyc.no_comm    +cond.no_comm     +tags.no_comm     +constrs.no_comm;
  summ.comm_gram  :=funcs.comm_gram   +cyc.comm_gram  +cond.comm_gram   +tags.comm_gram   +constrs.comm_gram;
  summ.comm_nogram:=funcs.comm_nogram +cyc.comm_nogram+cond.comm_nogram +tags.comm_nogram +constrs.comm_nogram;
  summ.all_numb   :=funcs.all_numb    +cyc.all_numb   +cond.all_numb    +tags.all_numb    +constrs.all_numb;
  make_mark_amount();
  make_mark_gram();
end;
//функция вывод отчета .txt
procedure make_out();
var
  k:integer;
  f:textfile;
begin
  k:=0;
  assignfile(f,proj_dir+'\Отчет_1.txt');
  rewrite(f);
  writeln(f,'Ресурсоемкость: ',av_res,' байт.');
  writeln(f,'Номера строк без комментариев: ');
  while k<=length(non)-1 do
    begin
      writeln(f,non[k]);
      k:=k+1;

    end;
  closefile(f);
end;
{**********************************************************************}
end.

