unit UGabesOddFormPanelChat;

interface

uses
  windows, classes, forms, graphics;

procedure CreateOddWindow(AHandle:THandle; ShowTitleBar:boolean);

implementation

procedure CreateOddWindow(AHandle:THandle; ShowTitleBar:boolean);
//-----------------------------------------------------------------------------//
//   Automatic created procedure by Gabe's Odd Form Assistant                  //
//                                                                             //
//   Add this unit to the uses clause of the form you would like to transform. //
//   Call this procedure from the form's OnCreate event like this:             //
//                                                                             //
//   procedure TMyForm.FormCreate(Sender: TObject);                            //
//   begin                                                                     //
//     CreateOddWindow(Handle, False);                                         //
//   end;                                                                      //
//                                                                             //
//   Parameters:                                                               //
//     AHandle:  The Handle of the form you want to transform to this shape.   //
//     ShowTitleBar: Decide whether the titlebar of the form is visible or not.//
//                                                                             //
//   Obs! The client area of the form should be of the same width as the       //
//   image you used to generate the source.                                    //
//                                                                             //
//   Informatics 1998-2000, http://www.informatics.no                          //
//   Made by Gabe: gabrielsen@informatics.no                                   //
//-----------------------------------------------------------------------------//
var
  R1, R2 : hRgn;
  dx : integer;
  dy : integer;
  Points : array [0..40] of TPoint;
begin
  dx := GetSystemMetrics(SM_CXFRAME);
  dy := GetSystemMetrics(SM_CYCAPTION)+GetSystemMetrics(SM_CYFRAME);

  if ShowTitleBar then
    R1 := CreateRectRgn(0, 0, 216 + dx*2 , dy )  //Obs! The client area of the form should be of the same width as the image you used to generate the source
  else
    R1 := CreateRectRgn(0,0,0,0);

  Points[0]:=Point(1 + dx,0 + dy);
  Points[1]:=Point(3 + dx,0 + dy);
  Points[2]:=Point(194 + dx,0 + dy);
  Points[3]:=Point(195 + dx,1 + dy);
  Points[4]:=Point(197 + dx,1 + dy);
  Points[5]:=Point(202 + dx,6 + dy);
  Points[6]:=Point(202 + dx,8 + dy);
  Points[7]:=Point(203 + dx,9 + dy);
  Points[8]:=Point(203 + dx,237 + dy);
  Points[9]:=Point(204 + dx,238 + dy);
  Points[10]:=Point(211 + dx,238 + dy);
  Points[11]:=Point(212 + dx,239 + dy);
  Points[12]:=Point(213 + dx,239 + dy);
  Points[13]:=Point(215 + dx,241 + dy);
  Points[14]:=Point(215 + dx,242 + dy);
  Points[15]:=Point(216 + dx,243 + dy);
  Points[16]:=Point(216 + dx,277 + dy);
  Points[17]:=Point(214 + dx,279 + dy);
  Points[18]:=Point(215 + dx,279 + dy);
  Points[19]:=Point(213 + dx,280 + dy);
  Points[20]:=Point(211 + dx,282 + dy);
  Points[21]:=Point(203 + dx,282 + dy);
  Points[22]:=Point(202 + dx,283 + dy);
  Points[23]:=Point(203 + dx,283 + dy);
  Points[24]:=Point(203 + dx,293 + dy);
  Points[25]:=Point(201 + dx,295 + dy);
  Points[26]:=Point(202 + dx,295 + dy);
  Points[27]:=Point(202 + dx,296 + dy);
  Points[28]:=Point(200 + dx,298 + dy);
  Points[29]:=Point(199 + dx,299 + dy);
  Points[30]:=Point(200 + dx,299 + dy);
  Points[31]:=Point(198 + dx,301 + dy);
  Points[32]:=Point(197 + dx,301 + dy);
  Points[33]:=Point(196 + dx,302 + dy);
  Points[34]:=Point(195 + dx,302 + dy);
  Points[35]:=Point(194 + dx,303 + dy);
  Points[36]:=Point(0 + dx,303 + dy);
  Points[37]:=Point(0 + dx,301 + dy);
  Points[38]:=Point(0 + dx,0 + dy);
  Points[39]:=Point(1 + dx,0 + dy);
  R2:=CreatePolygonRgn(Points[0],40,Winding);
  CombineRgn(R1,R1,R2,Rgn_XOR);
  SetWindowRgn(AHandle,R1,True);
end;

end.
