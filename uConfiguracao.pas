unit uConfiguracao;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls, ComCtrls, IniFiles, Vcl.Imaging.jpeg;

type
  TfrmConfiguracoes = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Linhas: TSpinEdit;
    Colunas: TSpinEdit;
    MandaLinha: TCheckBox;
    Image1: TImage;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    MQualidade: TLabel;
    Qualidade: TTrackBar;
    Compressao: TRadioGroup;
    Button1: TButton;
    Button2: TButton;
    Label5: TLabel;
    Zoom: TSpinEdit;
    Label6: TLabel;
    MandaQuadro: TCheckBox;
    Image2: TImage;
    procedure FormShow(Sender: TObject);
    procedure PintaImagem;
    procedure LinhasChange(Sender: TObject);
    procedure ColunasChange(Sender: TObject);
    procedure MandaLinhaClick(Sender: TObject);
    procedure GravaIni;
    procedure CarregaIni;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure QualidadeChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmConfiguracoes: TfrmConfiguracoes;

implementation

{$R *.dfm}

procedure TfrmConfiguracoes.ColunasChange(Sender: TObject);
begin
  PintaImagem;
end;

procedure TfrmConfiguracoes.FormCreate(Sender: TObject);
begin
   CarregaIni;
end;

procedure TfrmConfiguracoes.FormShow(Sender: TObject);
Begin
   CarregaIni;
   PintaImagem;
   MQualidade.Caption := IntToStr( Qualidade.Position );
end;

procedure TfrmConfiguracoes.LinhasChange(Sender: TObject);
begin
   PintaImagem;
end;

procedure TfrmConfiguracoes.MandaLinhaClick(Sender: TObject);
begin
   PintaImagem;
end;

procedure TfrmConfiguracoes.PintaImagem;
var
  P: TPoint;
  Calc: Integer;
  I: Integer;
  DuasColunas: Integer;
  TamanhoLinhas: Integer;
begin

   Image1.Canvas.Brush.Color := clWhite;
   Image1.Canvas.Pen.Color := clBlack;
   Image1.Canvas.Rectangle( 0, 0, 110, 110 );
   Calc := ( 110 div Linhas.Value );
   TamanhoLinhas := ( 110 div Linhas.Value );
   P.X := 0;
   P.Y := 0;
   for I := 1 to Linhas.Value do
      begin
         P.X := 0;
         P.Y := ( P.Y + Calc );
         if P.Y < 105 then
            begin
               Image1.Canvas.PenPos := P;
               Image1.Canvas.LineTo( 110, P.Y);
            end;
      end;
   Calc := ( 110 div Colunas.Value );
   P.X := 0;
   P.Y := 0;
   if Colunas.Value > 1 then
      DuasColunas := Calc *2
   else
      DuasColunas := Calc;
   for I := 1 to Colunas.Value do
      begin
         P.X := ( P.X + Calc );
         P.Y := 0;
         if P.X < 105 then
            begin
               Image1.Canvas.PenPos := P;
               Image1.Canvas.LineTo( P.X, 110);
            end;
      end;
   if MandaLinha.Checked then
      begin
         Image1.Canvas.Brush.Color := $00DDDDDD;
         Image1.Canvas.Rectangle( 0, 0, DuasColunas + 1, TamanhoLinhas + 1 );
      end;
end;

procedure TfrmConfiguracoes.QualidadeChange(Sender: TObject);
begin
   MQualidade.Caption := IntToStr( Qualidade.Position );
end;

procedure TfrmConfiguracoes.GravaIni;
var
  Ini: TIniFile;
begin
  //
  Ini := TIniFile.Create( ExtractFilePath( Application.ExeName ) + '\Z-Conf.ini' );
  Ini.WriteString( 'CONF', 'NUMEROLINHAS', Linhas.Text );
  Ini.WriteString( 'CONF', 'NUMEROCOLUNAS', Colunas.Text );
  case MandaLinha.Checked of
      False: Ini.WriteString( 'CONF', 'MANDALINHA', '0' );
      True: Ini.WriteString( 'CONF', 'MANDALINHA', '1' );
  end;
  case MandaQuadro.Checked of
      False: Ini.WriteString( 'CONF', 'MANDAQUADRO', '0' );
      True: Ini.WriteString( 'CONF', 'MANDAQUADRO', '1' );
  end;

  Ini.WriteString( 'CONF', 'QUALIDADE', IntToStr( Qualidade.Position ) );
  Ini.WriteString( 'CONF', 'COMPRESSAO', IntToStr( Compressao.ItemIndex ) );
  Ini.WriteString( 'CONF', 'ZOOM', IntToStr( Zoom.Value ) );

  Ini.Free;
end;

procedure TfrmConfiguracoes.Button1Click(Sender: TObject);
begin
   GravaIni;
   Close;
end;

procedure TfrmConfiguracoes.Button2Click(Sender: TObject);
begin
   Close;
end;

procedure TfrmConfiguracoes.CarregaIni;
var
   Ini: TIniFile;
begin
   if not FileExists(  ExtractFilePath( Application.ExeName ) + '\Z-Conf.ini'  ) then
      GravaIni;
   Ini := TIniFile.Create( ExtractFilePath( Application.ExeName ) + '\Z-Conf.ini' );
   Linhas.Text := Ini.ReadString(  'CONF', 'NUMEROLINHAS', '4' );
   Colunas.Text := Ini.ReadString(  'CONF', 'NUMEROCOLUNAS', '6' );
   Zoom.Text := Ini.ReadString(  'CONF', 'ZOOM', '70' );
   case StrToInt( Ini.ReadString(  'CONF', 'MANDALINHA', '1' ) ) of
      0: MandaLinha.Checked := False;
      1: MandaLinha.Checked := True;
   end;
   case StrToInt( Ini.ReadString(  'CONF', 'MANDAQUADRO', '1' ) ) of
      0: MandaQuadro.Checked := False;
      1: MandaQuadro.Checked := True;
   end;
   Qualidade.Position := StrToInt( Ini.ReadString( 'CONF', 'QUALIDADE', '30' ) );
   Compressao.ItemIndex := StrToInt( Ini.ReadString( 'CONF', 'COMPRESSAO', '3' ) );
   Ini.Free;
end;

end.
