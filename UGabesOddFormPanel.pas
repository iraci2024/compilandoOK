unit UGabesOddFormPanel;

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
  Points : array [0..50] of TPoint;
begin
  dx := GetSystemMetrics(SM_CXFRAME);
  dy := GetSystemMetrics(SM_CYCAPTION)+GetSystemMetrics(SM_CYFRAME);

  if ShowTitleBar then
    R1 := CreateRectRgn(0, 0, 602 + dx*2 , dy )  //Obs! The client area of the form should be of the same width as the image you used to generate the source
  else
  R1 := CreateRectRgn(0,0,0,0);

  Points[0]:=Point(1 + dx,7 + dy);
  Points[1]:=Point(1 + dx,4 + dy);
  Points[2]:=Point(4 + dx,1 + dy);
  Points[3]:=Point(6 + dx,1 + dy);
  Points[4]:=Point(6 + dx,0 + dy);
  Points[5]:=Point(8 + dx,0 + dy);
  Points[6]:=Point(597 + dx,0 + dy);
  Points[7]:=Point(598 + dx,1 + dy);
  Points[8]:=Point(599 + dx,1 + dy);
  Points[9]:=Point(601 + dx,3 + dy);
  Points[10]:=Point(601 + dx,4 + dy);
  Points[11]:=Point(602 + dx,5 + dy);
  Points[12]:=Point(602 + dx,44 + dy);
  Points[13]:=Point(600 + dx,46 + dy);
  Points[14]:=Point(601 + dx,46 + dy);
  Points[15]:=Point(599 + dx,48 + dy);
  Points[16]:=Point(597 + dx,50 + dy);
  Points[17]:=Point(595 + dx,50 + dy);
  Points[18]:=Point(594 + dx,51 + dy);
  Points[19]:=Point(56 + dx,51 + dy);
  Points[20]:=Point(55 + dx,52 + dy);
  Points[21]:=Point(56 + dx,52 + dy);
  Points[22]:=Point(56 + dx,56 + dy);
  Points[23]:=Point(54 + dx,58 + dy);
  Points[24]:=Point(55 + dx,58 + dy);
  Points[25]:=Point(53 + dx,60 + dy);
  Points[26]:=Point(51 + dx,62 + dy);
  Points[27]:=Point(49 + dx,62 + dy);
  Points[28]:=Point(48 + dx,63 + dy);
  Points[29]:=Point(29 + dx,63 + dy);
  Points[30]:=Point(28 + dx,61 + dy);
  Points[31]:=Point(27 + dx,62 + dy);
  Points[32]:=Point(26 + dx,62 + dy);
  Points[33]:=Point(25 + dx,60 + dy);
  Points[34]:=Point(22 + dx,57 + dy);
  Points[35]:=Point(22 + dx,55 + dy);
  Points[36]:=Point(21 + dx,54 + dy);
  Points[37]:=Point(21 + dx,51 + dy);
  Points[38]:=Point(20 + dx,50 + dy);
  Points[39]:=Point(19 + dx,51 + dy);
  Points[40]:=Point(8 + dx,51 + dy);
  Points[41]:=Point(7 + dx,49 + dy);
  Points[42]:=Point(6 + dx,50 + dy);
  Points[43]:=Point(5 + dx,50 + dy);
  Points[44]:=Point(4 + dx,48 + dy);
  Points[45]:=Point(1 + dx,45 + dy);
  Points[46]:=Point(1 + dx,43 + dy);
  Points[47]:=Point(0 + dx,42 + dy);
  Points[48]:=Point(0 + dx,7 + dy);
  Points[49]:=Point(1 + dx,7 + dy);
  R2:=CreatePolygonRgn(Points[0],50,Winding);
  CombineRgn(R1,R1,R2,Rgn_XOR);
  SetWindowRgn(AHandle,R1,True);
end;

end.
