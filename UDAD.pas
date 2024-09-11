unit UDAD;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Vcl.Buttons,ScktComp, Vcl.MPlayer,
  Vcl.Grids, Vcl.DBGrids, Vcl.DBCtrls, Data.DB, Datasnap.DBClient;

type
  TFUDAD = class(TForm)
    Image1: TImage;
    Image2: TImage;
    CurvyPanel1: Tpanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    edTexto: TRichEdit;
    SpeedButton1: TSpeedButton;
    RichPws: TRichEdit;
    procedure Image2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    SocketD:TCustomWinSocket;

    procedure InsereTexto(Texto: String; Stylo: TFontStyles; Cor: TColor;
       TamanhoFonte: Integer );

  end;

var
  FUDAD: TFUDAD;

implementation

uses   UGabesOddFormPanelChat, UFSessao, UFCPrin;

{$R *.dfm}

procedure TFUDAD.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//Action:=caFree;
FreeAndNil(Self);
end;

procedure TFUDAD.FormShow(Sender: TObject);
var
L: TListItem;
begin
L := FCPrin.LV1.FindCaption(0, intToStr(SocketD.Handle), false, true, false);
if L <> nil then
begin
  Parent := (l.SubItems.Objects[2] as TFSESSAO);
  edTexto.Clear;
  CreateOddWindow((l.SubItems.Objects[4] as TFUDAD).Handle, False );

end;

end;

procedure TFUDAD.Image2Click(Sender: TObject);
var
L: TListItem;
begin
L := FCPrin.LV1.FindCaption(0, intToStr(SocketD.Handle), false, true, false);
if L <> nil then
begin
 (l.SubItems.Objects[2] as TFSESSAO).tmrDado.Enabled:=true;
end;
end;

procedure TFUDAD.InsereTexto(Texto: String; Stylo: TFontStyles; Cor: TColor;
  TamanhoFonte: Integer);
begin
end;


procedure TFUDAD.SpeedButton1Click(Sender: TObject);
begin
edTexto.Clear;
end;

end.

