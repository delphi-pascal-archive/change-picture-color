unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ExtDlgs, ComCtrls, StdCtrls, ColorGrd, JPEG;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    OpenPictureDialog1: TOpenPictureDialog;
    Image1: TImage;
    Image2: TImage;
    Panel3: TPanel;
    Panel2: TPanel;
    Image3: TImage;
    Panel4: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Image3MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Panel3Click(Sender: TObject);
    procedure Panel4Click(Sender: TObject);
  private
    { Déclarations privées }
    procedure arcenciel;
    procedure coloriser(acolor : tcolor);
    Procedure BmpCouleur(couleur: tcolor);
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;
  bitmap1 : tbitmap;
  bitmap2 : Tbitmap;

implementation

{$R *.DFM}

type
  TRGBArray = ARRAY[0..0] OF TRGBTriple;   // élément de bitmap (API windows)
  pRGBArray = ^TRGBArray;     // type pointeur vers tableau 3 octets 24 bits


procedure TForm1.FormCreate(Sender: TObject);
begin
  bitmap1 := tbitmap.create;
  bitmap1.width := 8;
  bitmap1.height := 8;
  bitmap2 := tbitmap.create;
  bitmap2.width := 8;
  bitmap2.height := 8;
  arcenciel;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  bitmap1.free;
  bitmap2.free;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  close;
end;



function mini(a,b : integer): integer;
begin
  if a < b then result := a else result := b;
end;

function maxi(a,b : integer): integer;
begin
  if a > b then result := a else result := b;
end;

Procedure HSVtoRGB (const zH, zS, zV: integer; var aR, aG, aB: integer);
const
  d = 255*60;
var
  a    : integer;
  hh   : integer;
  p,q,t: integer;
  vs   : integer;
begin
  if (zH = 0) or (zS = 0) or (ZV = 0)  then    // niveaux de gris
  begin
    aR := zV;
    aG := zV;
    aB := zV;
  end
  else
  begin              // en couleur
    if zH = 360 then hh := 0 else hh := zH;
    a  := hh mod 60;     // a intervalle  0..59
    hh := hh div 60;    // hh intervalle 0..6
    vs := zV * zS;
    p  := zV - vs div 255;              // p = v * (1 - s)
    q  := zV - (vs*a) div d;            // q = v * (1 - s*a)
    t  := zV - (vs*(60 - a)) div d;     // t = v * (1 - s * (1 - f))
    case hh of
    0: begin aR := zV; aG :=  t ; aB :=  p; end;
    1: begin aR :=  q; aG := zV ; aB :=  p; end;
    2: begin aR :=  p; aG := zV ; aB :=  t; end;
    3: begin aR :=  p; aG :=  q ; aB := zV; end;
    4: begin aR :=  t; aG :=  p ; aB := zV; end;
    5: begin aR := zV; aG :=  p ; aB :=  q; end;
    else begin aR := 0; aG := 0 ; aB := 0; end;
    end;  // case
  end;
end;


// RGB = Red Green Blue intervalle 0..255
// Hue          H = 0° to 360° (correspond à la couleur)
// Saturation   S = 0 (niveau de gris)  à 255 (couleur pure)
// Valeur       V = 0 (noir) à 255 (blanc)

procedure RGBtoHSV(const aR, aG,aB: integer; var zH, zS, zV: integer);
var
  Delta : integer;
  Min   : integer;
begin
  Min := mini(aR, mini(aG,aB));
  zV   := maxi(aR, maxi(aG,aB));
  Delta := zV - Min;
  // Saturation
  if zV =  0 then    // valeur maxi = 0 donc noir
     zS := 0 else zS := (Delta*255) div zV;
  if zS  = 0 then    // pas de saturation
     zH := 0         // donc niveau de gris
  else
  begin                   // couleur
    if aR = zV then         // dominante rouge -> entre jaune et violet
    zH := ((aG-aB)*60) div delta
    else
    if aG = zV then         // dominante vert  -> entre bleu-vert et jaune
    zH := 120 + ((aB-aR)*60) div Delta
    else
    if  aB = zV then        // dominante bleu  -> entre violet et bleu vert
    zH := 240 + ((aR-aG)*60) div Delta;
    if zH <= 0 then zH := zH + 360;  // intervalle 0..359°
  end;
end;

Procedure Tform1.BmpCouleur(couleur: tcolor);
var
  x, y : integer;      // index pixels
  Rowa : Prgbarray;    // scanlines
  Rowb : Prgbarray;
  R,G,B : integer;
  R0,G0,B0 : integer;
  H0       : integer;
  H,S,V    : integer;
begin
  R0 := GetRValue( ColorToRGB(couleur));
  G0 := GetGValue( ColorToRGB(couleur));
  B0 := GetBValue( ColorToRGB(couleur));
  RGBtoHSV(R0, G0, B0, H, S, V);
  H0 := H;       // on ne mémorise que la couleur (hue)
  For y := 0 to bitmap2.height-1 do
  begin
    rowa := Bitmap1.scanline[y];
    rowb := Bitmap2.scanline[y];
    for x := 0 to bitmap2.width-1 do
    begin
      R := rowa[x].RgbtRed;
      G := rowa[x].Rgbtgreen;
      B := rowa[x].Rgbtblue;
      // récupération saturation et valeur
      RGBtoHSV(R, G, B, H, S, V);
      HSVtoRGB(H0, S, V, R, G, B);  // on répartit la couleur demandée
      // Validité des couleurs
      if R > 255 then R := 255 else if R < 0 then R := 0;
      if G > 255 then G := 255 else if G < 0 then G := 0;
      if B > 255 then B := 255 else if B < 0 then B := 0;
      rowb[x].Rgbtred   := R;
      rowb[x].Rgbtgreen := G;
      rowb[x].Rgbtblue  := B;
    end;
  end;
end;

procedure Tform1.coloriser(acolor : tcolor);
begin
  bitmap1.free;
  bitmap1 := tbitmap.create;
  bitmap1.pixelformat := pf24bit;
  bitmap1.width  := image1.width;
  bitmap1.height := image1.height;
  bitmap1.canvas.draw(0,0, image1.picture.graphic);
  bitmap2.free;
  bitmap2 := tbitmap.create;
  bitmap2.pixelformat := pf24bit;
  bitmap2.width  := image1.width;
  bitmap2.height := image1.height;
  bmpcouleur(acolor);
  image2.picture.assign(bitmap2);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if openpicturedialog1.execute then
  begin
    image1.picture.loadfromfile(openpicturedialog1.filename);
  end;
end;


procedure Tform1.arcenciel;
var
  i : integer;
  colo : Tcolor;
  R,G,B : integer;
begin
  for i := 1 to image3.width do  // paintbox fait 360 pixels de long
  begin
    HSVtoRGB(i, 255, 255, R, G, B);
    colo := RGB(R,G,B);
    with image3.canvas do
    begin
      pen.color := colo;
      moveto(i,0);
      lineto(i, image3.height);
    end;
  end;
end;

procedure TForm1.Image3MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  panel4.color := image3.canvas.pixels[X,Y];
  coloriser(panel4.color);
end;

procedure TForm1.Panel3Click(Sender: TObject);
begin
  coloriser(panel3.color);
end;

procedure TForm1.Panel4Click(Sender: TObject);
begin
  coloriser(panel4.color);
end;

end.



