unit thumbcontrol;

//22.6.2010 Theo
//Git push 30.1.2013

{$MODE objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, scrollingcontrol, ThreadedImageLoader,
  Graphics, fpImage, FPReadJPEGthumb, fpthumbresize, LResources,
  FileUtil, Dialogs, GraphType, LCLType, LCLIntf, Types;


type
  TLayoutStyle = (LsAuto, LsAutoSize, LsHorizFixed, LsVertFixed, LsHorizAutoSize, LsVertAutoSize, LsGrid);
  TInternalLayoutStyle = (IlsHorz, IlsVert, IlsGrid);

  TSelectItemEvent = procedure(Sender: TObject; Item: TThreadedImage) of object;
  TLoadFileEvent = procedure(Sender: TObject; URL: string; out Stream: TStream) of object;

{ TThumbControl }

  TThumbControl = class(TScrollingControl)
  private
    FArrangeStyle: TLayoutStyle;
    FIls: TInternalLayoutStyle;
    fContentWidth: integer;
    fContentHeight: integer;
    FDirectory: UTF8String;
    fMngr: TImageLoaderManager;
    FOnLoadFile: TLoadFileEvent;
    FShowPictureFrame: Boolean;
    FShowCaptions: Boolean;
    fAutoSort: boolean;
    fThumbWidth: integer;
    fThumbHeight: integer;
    FURLList: TStringList;
    fUserThumbWidth: integer;
    fUserThumbHeight: integer;
    fFrame: TBitmap;
    fThumbDist: integer; //Distance between thumbnails
    fPictureFrameBorder: integer; //One Border of blacke picture frame
    fTextExtraHeight: integer;
    fLeftOffset: integer; //first frame left offset
    fTopOffset: integer;
    fOnSelectItem: TSelectItemEvent;
    fWindowCreated: Boolean;
    fGridThumbsPerLine: integer;
    function GetFreeInvisibleImages: boolean;
    function GetMultiThreaded: boolean;
    function GetURLList: UTF8String;
    procedure Init;
    procedure SetArrangeStyle(const AValue: TLayoutStyle);
    procedure SetAutoSort(AValue: boolean);
    procedure SetDirectory(const AValue: UTF8String);
    procedure SetFreeInvisibleImages(const AValue: boolean);
    procedure SetMultiThreaded(const AValue: boolean);
    procedure SetShowPictureFrame(const AValue: Boolean);
    procedure SetShowCaptions(const AValue: Boolean);
    procedure SetThumbDistance(const AValue: integer);
    procedure SetThumbHeight(const AValue: integer);
    procedure SetThumbWidth(const AValue: integer);
    procedure AsyncFocus(Data: PtrInt);
    procedure SetURLList(const AValue: UTF8String);
  protected
    class function GetControlClassDefaultSize: TSize; override;
    procedure BoundsChanged; override;
    procedure Paint; override;
    procedure ImgLoadURL(Sender: TObject);
    procedure ImgLoaded(Sender: TObject);
    procedure Search;
    procedure FileFoundEvent(FileIterator: TFileIterator);
    procedure CreateWnd; override;
    procedure Click; override;
    procedure DoSelectItem; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure UpdateDims;
    procedure Arrange;
    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy;
      const AXProportion, AYProportion: Double); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultColor(const DefaultColorType: TDefaultColorType): TColor; override;
    {:Use this function when you need the item from control coordinates (Mouse etc.)}
    function ItemFromPoint(APoint: TPoint): TThreadedImage;
    procedure ScrollIntoView;
    procedure LoadSelectedBitmap(ABitmap:TBitmap);
    property URLList: UTF8String read GetURLList write SetURLList;
    property ImageLoaderManager: TImageLoaderManager read fMngr;
  published
    property Directory: UTF8String read FDirectory write SetDirectory stored True nodefault;
    property ThumbWidth: integer read fUserThumbWidth write SetThumbWidth;
    property ThumbHeight: integer read fUserThumbHeight write SetThumbHeight;
    property ThumbDistance: integer read fThumbDist write SetThumbDistance;
    {:If you set MultiThreaded to true, the images will be loaded in the "background" not blocking the application.
      Warning: The debugger GDB may not like this setting. Be careful in OnLoadFile in this mode}
    property MultiThreaded: boolean read GetMultiThreaded write SetMultiThreaded;
    {:Show/Hide the filename captions.}
    property ShowCaptions: Boolean read FShowCaptions write SetShowCaptions;
    {:Show/Hide picture Frame}
    property ShowPictureFrame: Boolean read FShowPictureFrame write SetShowPictureFrame;
    {:Different modes, basically horizontal, vertical and grid plus autosize and auto layout modes, depending on the size of the control}
    property Layout: TLayoutStyle read FArrangeStyle write SetArrangeStyle;
    {:Do not keep in memory the bitmaps that are currently invisble. (Slower but less resource hungry).}
    property FreeInvisibleImages: boolean read GetFreeInvisibleImages write SetFreeInvisibleImages;
    {:Event triggered when a thumbnail is clicked or selected using the enter key.}
    property OnSelectItem: TSelectItemEvent read fOnSelectItem write fOnSelectItem;
    {:Event when image stream data is required. Useful for loading data via http, ftp etc.
      Warning: if MultiThreaded=true, this happens in a separate thread context.}
    property AutoSort : boolean read fAutoSort write SetAutoSort;
    {:Sort URL by name}
    property OnLoadFile: TLoadFileEvent read FOnLoadFile write FOnLoadFile;
    property ScrollBars;
    property Align;
    property Anchors;
    property AutoSize;
    property BidiMode;
    property BorderSpacing;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBidiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChangeBounds;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDockDrop;
    property OnDockOver;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnUTF8KeyPress;


  end;

var frame: TPortableNetworkGraphic;

const StockBorderWidth = 15;
  StockTextExtraHeight = 8;

procedure Register;

implementation

uses Forms, fontfinder,
fpreadgif,FPReadPSD,FPReadPCX,FPReadTGA, LazFileUtils, LazUTF8; //just register them

function ShortenString(AValue: string; Width: integer; ACanvas: TCanvas): string;
var len, slen: integer;
  NewLen: integer;
begin
  len := ACanvas.TextWidth(AValue);
  if len > width then
  begin
    NewLen := ((Length(AValue) * width) div len) - 1;
    slen := Length(AValue);
//  Result:=Copy(AValue,1,NewLen); //End crop
    Result := Copy(AValue, 1, (NewLen) div 2) + '..' + Copy(AValue, slen - ((NewLen) div 2), slen);
  end else Result := AValue;
end;


{ TThumbControl }

procedure TThumbControl.SetDirectory(const AValue: UTF8String);
begin
  if GetMultiThreaded and (not fMngr.ThreadsIdle) then
  Repeat
    Application.ProcessMessages;
  until fMngr.ThreadsIdle;

  if AValue = '' then fDirectory := 'none' else fDirectory := AValue;
  if (fDirectory <> 'none') and (fDirectory <> '') then
    if DirectoryExistsUTF8(AValue) then
    begin
      if (csLoading in ComponentState) then exit;
      Init;
      Invalidate;
    end;
end;


procedure TThumbControl.Init;
begin
  if not (csDesigning in ComponentState) then
  begin
    fMngr.Clear;
    Search;
    if fAutoSort then fMngr.Sort(0);
    Arrange;
  end else
  begin
    fMngr.Clear;
    fMngr.AddImage('');
    fMngr.AddImage('');
    fMngr.AddImage('');
    Arrange;
  end;
end;



procedure TThumbControl.SetFreeInvisibleImages(const AValue: boolean);
begin
  fMngr.FreeInvisibleImage := AValue;
end;


procedure TThumbControl.SetURLList(const AValue: UTF8String);
var i: integer;
begin
  fMngr.Clear;
  FURLList.Text := AValue;
  for i := 0 to FURLList.Count - 1 do fMngr.AddImage(FURLList[i]);
  if fAutoSort then fMngr.Sort(0);
  Arrange;
end;


function TThumbControl.GetMultiThreaded: boolean;
begin
  if Assigned(fMngr) then Result := fMngr.MultiThreaded;
end;

function TThumbControl.GetFreeInvisibleImages: boolean;
begin
  Result := fMngr.FreeInvisibleImage;
end;

function TThumbControl.GetURLList: UTF8String;
begin
  Result := FURLList.Text;
end;

procedure TThumbControl.SetArrangeStyle(const AValue: TLayoutStyle);
begin
  if FArrangeStyle <> AValue then
  begin
    FArrangeStyle := AValue;
    if not (csLoading in ComponentState) then
    begin
      Arrange;
      Invalidate;
    end;
  end;
end;

procedure TThumbControl.SetAutoSort(AValue: boolean);
begin
  if fAutoSort=AValue then Exit;
  fAutoSort:=AValue;
  fMngr.Sort(0);
end;

procedure TThumbControl.SetMultiThreaded(const AValue: boolean);
begin
  if Assigned(fMngr) then fMngr.MultiThreaded := AValue;
end;

procedure TThumbControl.SetShowPictureFrame(const AValue: Boolean);
begin
  FShowPictureFrame := AValue;
  if FShowPictureFrame then
  begin
    fPictureFrameBorder := Scale96ToFont(StockBorderWidth);
    if FShowCaptions then fTextExtraHeight := 0;
  end else
  begin
    fPictureFrameBorder := 0;
    if FShowCaptions then fTextExtraHeight := StockTextExtraHeight;
  end;
  if not (csLoading in ComponentState) then
  begin
    Arrange;
    Invalidate;
  end;
end;

procedure TThumbControl.SetShowCaptions(const AValue: Boolean);
begin
  FShowCaptions := AValue;
  if FShowCaptions and (not FShowPictureFrame) then fTextExtraHeight := StockTextExtraHeight else fTextExtraHeight := 0;
  if not (csLoading in ComponentState) then
  begin
    Arrange;
    Invalidate;
  end;
end;

procedure TThumbControl.SetThumbDistance(const AValue: integer);
begin
  if fThumbDist <> AValue then
  begin
    fThumbDist := AValue;
    if not (csLoading in ComponentState) then
    begin
      Arrange;
      Invalidate;
    end;
  end;
end;

procedure TThumbControl.SetThumbHeight(const AValue: integer);
begin
  if fThumbHeight <> AValue then
  begin
    fThumbHeight := AValue;
    fUserThumbHeight := AValue;
    if not (csLoading in ComponentState) then
    begin
      Arrange;
      Invalidate;
    end;
  end;
end;

procedure TThumbControl.SetThumbWidth(const AValue: integer);
begin
  if fThumbWidth <> AValue then
  begin
    fThumbWidth := AValue;
    fUserThumbWidth := AValue;
    SmallStep := fThumbWidth;
    LargeStep := fThumbWidth * 4;
    if not (csLoading in ComponentState) then
    begin
      Arrange;
      Invalidate;
    end;
  end;
end;


procedure TThumbControl.CreateWnd;
begin
  inherited CreateWnd;
  fWindowCreated := true;
  Init;
end;


procedure TThumbControl.Click;
var Idx: Integer;
  pt: TPoint;
begin
  pt := ScreenToClient(Mouse.CursorPos);
  Idx := fMngr.ItemIndexFromPoint(Point(pt.X + HScrollPosition, pt.Y + VScrollPosition));
  inherited;
  if Idx > -1 then
  begin
    fMngr.ActiveIndex := Idx;
    DoSelectItem;
    Invalidate;
  end;
  SetFocus;
end;

procedure TThumbControl.DoSelectItem;
begin
  if Assigned(fOnSelectItem) then OnSelectItem(Self, fMngr.ActiveItem);
end;

procedure TThumbControl.AsyncFocus(Data: PtrInt);
begin
  SetFocus;
end;

procedure TThumbControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case key of
    VK_LEFT: begin fMngr.ActiveIndex := fMngr.ActiveIndex - 1; ScrollIntoView; end;
    VK_RIGHT: begin fMngr.ActiveIndex := fMngr.ActiveIndex + 1; ScrollIntoView; end;

    VK_UP: if FIls = IlsGrid then
      begin
        fMngr.ActiveIndex := fMngr.ActiveIndex - fGridThumbsPerLine; ScrollIntoView;
      end else
      begin fMngr.ActiveIndex := fMngr.ActiveIndex - 1;
        ScrollIntoView;
      end;

    VK_DOWN: if FIls = IlsGrid then
      begin
        fMngr.ActiveIndex := fMngr.ActiveIndex + fGridThumbsPerLine; ScrollIntoView;
      end else
      begin fMngr.ActiveIndex := fMngr.ActiveIndex + 1;
        ScrollIntoView;
      end;
    VK_RETURN: DoSelectItem;
    VK_PRIOR: if (FIls = IlsVert) or (FIls = IlsGrid) then
        VScrollPosition := VScrollPosition - ClientHeight else HScrollPosition := HScrollPosition - ClientWidth;
    VK_NEXT: if (FIls = IlsVert) or (FIls = IlsGrid) then
        VScrollPosition := VScrollPosition + ClientHeight else HScrollPosition := HScrollPosition + ClientWidth;
  end;
  Invalidate;
  Application.QueueAsyncCall(@AsyncFocus, 0);
end;

procedure TThumbControl.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  SetFocus;
end;

procedure TThumbControl.ScrollIntoView;
var itm: TThreadedImage;
  Dum, ARect: TRect;
begin
  itm := fMngr.ActiveItem;
  if itm <> nil then
  begin
    ARect := ClientRect;
    OffsetRect(ARect, HScrollPosition, VScrollPosition);

    if IntersectRect(Dum, ARect, itm.Rect) then exit;

    HScrollPosition := 0;
    VScrollPosition := 0;

    if (FIls = IlsHorz) then
      if Abs(Arect.Left - Itm.Rect.Left) > (Arect.Right - Itm.Rect.Right) then
        HScrollPosition := itm.Rect.Right - ClientWidth + fPictureFrameBorder + fThumbDist else
        HScrollPosition := itm.Rect.Left - ClientWidth - fPictureFrameBorder - fThumbDist + ClientWidth;

    if (FIls = IlsVert) or (FIls = IlsGrid) then
      if Abs(Arect.Top - Itm.Rect.Top) > (Arect.Bottom - Itm.Rect.Bottom) then
        VScrollPosition := itm.Rect.Bottom - ClientHeight + fPictureFrameBorder + fThumbDist else
        VScrollPosition := itm.Rect.Top - ClientHeight - fPictureFrameBorder - fThumbDist + ClientHeight;
    UpdateDims;
  end;
end;



procedure TThumbControl.BoundsChanged;
begin
  inherited BoundsChanged;
  if fWindowCreated and not ((csLoading in ComponentState)) and Visible then
  begin
    Arrange;
    UpdateDims;
    ScrollIntoView;
  end;
end;


procedure TThumbControl.Paint;
var i, tlen: integer;
  aRect, BorderRect, Dum: TRect;
  UrlStr: string;
  Clipped: boolean;
  Cim: TThreadedImage;
begin
  begin
    if Canvas.Clipping {$ifdef LCLQt} and false {$endif} then
    begin
      ARect := Canvas.ClipRect;
      Clipped := not EqualRect(ARect, ClientRect);
    end else
    begin
      ARect := ClientRect;
      Clipped := false;
    end;

    if Color = clDefault then
      Canvas.Brush.Color := GetDefaultColor(dctBrush)
    else
      Canvas.Brush.Color := Color;
    Canvas.FillRect(ARect);
    OffsetRect(aRect, HScrollPosition, VScrollPosition);
    if not clipped then fMngr.LoadRect(ARect);

    Canvas.Brush.color := $F1F1F1;

    for i := 0 to fmngr.List.Count - 1 do
    begin
      Cim := TThreadedImage(fmngr.List[i]);
      BorderRect := Cim.Rect;
      if IntersectRect(Dum, BorderRect, Arect) then
      begin
        OffSetRect(BorderRect, -HScrollPosition, -VScrollPosition);
        if fShowPictureFrame then
          Canvas.Draw(BorderRect.Left - fPictureFrameBorder, BorderRect.Top - fPictureFrameBorder, fFrame) else
        begin
          InflateRect(BorderRect, 1, 1);
          Canvas.Brush.Style := bsClear;
          Canvas.Pen.Color := clLtGray;
          Canvas.Rectangle(BorderRect);
          Canvas.Brush.Style := bsSolid;
        end;

        if Cim.LoadState = lsLoaded then
        begin
          Canvas.Draw(Cim.Left + Cim.Area.Left - HScrollPosition,
            Cim.Top + Cim.Area.Top - VScrollPosition,
            Cim.Bitmap);
           if i = fMngr.ActiveIndex then
          begin
            BorderRect := Cim.Area;
            OffSetRect(BorderRect, -HScrollPosition + Cim.Rect.Left,
              -VScrollPosition + Cim.Rect.Top);
            InflateRect(BorderRect, 1, 1);
            Canvas.Brush.Style := bsClear;
            Canvas.Pen.Color := $448FA2;
            Canvas.Pen.Width := 2;
            Canvas.Rectangle(BorderRect);
            Canvas.Pen.Width := 1;
            Canvas.Brush.Style := bsSolid;
          end;
        end;

        if fShowCaptions then
        begin
          if Cim.URL = '' then
            UrlStr := ShortenString('Undefined', Cim.Width, Canvas) else
            UrlStr := ShortenString(ExtractFileName(Cim.URL),
              Cim.Width, Canvas);
          tlen := (Cim.Width - Canvas.TextWidth(UrlStr)) div 2;
          if not FShowPictureFrame then
            if i = fMngr.ActiveIndex then Canvas.Font.color := clGray else Canvas.Font.color := ClBlack else
          begin
            Canvas.Brush.Style := bsSolid;
            Canvas.Brush.Color := clBlack;
            Canvas.FillRect(Cim.Left - HScrollPosition + tlen - 1,
              Cim.Height + Cim.Top - VScrollPosition + 1,
              Cim.Left - HScrollPosition + Scale96ToFont(2) + tlen + Canvas.TextWidth(UrlStr),
              Cim.Height + Cim.Top - VScrollPosition + Scale96ToFont(10));
            if i = fMngr.ActiveIndex then Canvas.Font.color := clWhite else Canvas.Font.color := $448FA2;
          end;
          Canvas.Brush.Style := bsClear;
          Canvas.TextOut(
            Cim.Left - HScrollPosition + 1 + tlen,
            Cim.Height + Cim.Top - VScrollPosition - 1,
            UrlStr);
          Canvas.Brush.Style := bsSolid;
        end;
      end;
    end;
  end;
  inherited Paint;
end;

function GetFPReaderMask: string;
var i, j: integer;
  sl: TStringList;
begin
  Result := '';
  sl := TStringList.Create;
  sl.Delimiter := ';';
  for i := 0 to ImageHandlers.Count - 1 do
  begin
    sl.DelimitedText := ImageHandlers.Extensions[ImageHandlers.TypeNames[i]];
    for j := 0 to sl.Count - 1 do Result := Result + '*.' + sl[j] + ';';
  end;
  sl.free;
end;

procedure TThumbControl.Search;
var fi: TFileSearcher;
begin
  fi := TFileSearcher.Create;
  fi.OnFileFound := @FileFoundEvent;
//fi.Search(FDirectory, GraphicFileMask(TGraphic), false);
  try
    fi.Search(FDirectory, GetFPReaderMask, false);
  finally
    fi.free;
  end;
end;

procedure TThumbControl.FileFoundEvent(FileIterator: TFileIterator);
begin
  fMngr.AddImage(FileIterator.FileName);
end;


procedure TThumbControl.Arrange;
var i, x, y, aDim: integer;
begin
  if FArrangeStyle = LsHorizFixed then FIls := IlsHorz else
    if FArrangeStyle = LsVertFixed then FIls := IlsVert else
      if FArrangeStyle = LsGrid then FIls := IlsGrid;
  if (FArrangeStyle = LsAuto) or (FArrangeStyle = LsAutoSize) then
  begin
    if width > height then FIls := IlsHorz else FIls := IlsVert;
    if (width > 2 * fUserThumbWidth + 4 * fPictureFrameBorder) and
    (Height > 2 * fUserThumbHeight + 4 * fPictureFrameBorder) then FIls := IlsGrid;
  end;

  if (FArrangeStyle = LsHorizFixed) or (FArrangeStyle = LsVertFixed) or
    (FArrangeStyle = LsGrid) or (FArrangeStyle = LsAuto) or (FIls = IlsGrid) then
  begin
    if (fUserThumbWidth <> fThumbWidth) or (fUserThumbHeight <> fThumbHeight) then
    begin
      fThumbHeight := fUserThumbHeight;
      fThumbWidth := fUserThumbWidth;
      fMngr.FreeImages;
      Invalidate;
    end;
  end;

  if (FArrangeStyle = LsHorizAutoSize) or ((FArrangeStyle = LsAutoSize) and (FIls = IlsHorz)) then
  begin
    aDim := fThumbHeight;
    fThumbHeight := ClientHeight - fPictureFrameBorder * 2 - fTextExtraHeight - 2 * fTopOffset - Scale96ToFont(20);
    fThumbWidth := Round(fThumbHeight / fUserThumbHeight * fUserThumbWidth);
    FIls := IlsHorz;
    if ADim <> fThumbHeight then
    begin
      fMngr.FreeImages;
      Invalidate;
    end;
  end;

  if (FArrangeStyle = LsVertAutoSize) or ((FArrangeStyle = LsAutoSize) and (FIls = IlsVert)) then
  begin
    aDim := fThumbWidth;
    fThumbWidth := ClientWidth - fPictureFrameBorder * 2 - 2 * fLeftOffset - Scale96ToFont(20);
    fThumbHeight := Round(fThumbWidth / fUserThumbWidth * fUserThumbHeight);
    FIls := IlsVert;
    if ADim <> fThumbWidth then
    begin
      fMngr.FreeImages;
      Invalidate;
    end;
  end;

  if FShowPictureFrame then
  begin
    fFrame.SetSize(fThumbWidth + fPictureFrameBorder * 2, fThumbHeight + fPictureFrameBorder * 2);
    fFrame.Canvas.Brush.FPColor := TColorToFPColor(clWhite);
    fFrame.Canvas.FillRect(0, 0, fFrame.Width, fFrame.Height);
    fFrame.Canvas.StretchDraw(Rect(0, 0, fFrame.Width, fFrame.Height), frame);
  end;

  if FIls = IlsHorz then
  begin
    for i := 0 to fMngr.List.Count - 1 do
    begin
      TThreadedImage(fMngr.List[i]).Width := fThumbWidth;
      TThreadedImage(fMngr.List[i]).Height := fThumbHeight;
      TThreadedImage(fMngr.List[i]).Left := i * (fThumbWidth + fThumbDist +
      fPictureFrameBorder * 2) +  fLeftOffset + fPictureFrameBorder;
      TThreadedImage(fMngr.List[i]).Top := fTopOffset + fPictureFrameBorder;
    end;
    fContentWidth := fMngr.List.Count * (fThumbWidth + fThumbDist + fPictureFrameBorder * 2) + fLeftOffset;
    fContentHeight := fThumbHeight + fPictureFrameBorder * 2 + fTopOffset;
  end;

  if FIls = IlsVert then
  begin
    for i := 0 to fMngr.List.Count - 1 do
    begin
      TThreadedImage(fMngr.List[i]).Width := fThumbWidth;
      TThreadedImage(fMngr.List[i]).Height := fThumbHeight;
      TThreadedImage(fMngr.List[i]).Left := fLeftOffset + fPictureFrameBorder;
      TThreadedImage(fMngr.List[i]).Top := i * (fThumbHeight + fThumbDist +
      fTextExtraHeight + fPictureFrameBorder * 2) + fTopOffset + fPictureFrameBorder;
    end;
    fContentHeight := (fMngr.List.Count) * (fThumbHeight + fTextExtraHeight + fThumbDist +
    fPictureFrameBorder * 2) + fTopOffset;
    fContentWidth := fThumbWidth + fPictureFrameBorder * 2 + fLeftOffset;
  end;

  if FIls = IlsGrid then
  begin
    y := 0;
    x := 0;
    fGridThumbsPerLine := ClientWidth div (fThumbWidth + fThumbDist + fPictureFrameBorder * 2);
    for i := 0 to fMngr.List.Count - 1 do
    begin
      if (i > 0) then
        if (i mod fGridThumbsPerLine = 0) then
        begin
          inc(y, (fThumbHeight + fThumbDist + fTextExtraHeight + fPictureFrameBorder * 2));
          x := 0;
        end
        else inc(x);
      TThreadedImage(fMngr.List[i]).Width := fThumbWidth;
      TThreadedImage(fMngr.List[i]).Height := fThumbHeight;
      TThreadedImage(fMngr.List[i]).Left := x * (fThumbWidth + fThumbDist + fPictureFrameBorder * 2) +
      fLeftOffset + fPictureFrameBorder;
      TThreadedImage(fMngr.List[i]).Top := y + fTopOffset + fPictureFrameBorder;
    end;
    fContentHeight := (fMngr.List.Count div fGridThumbsPerLine + 1) * (fThumbHeight +
    fTextExtraHeight + fThumbDist + fPictureFrameBorder * 2) + fTopOffset;
    fContentWidth := ClientWidth;
  end;


  if fContentWidth <= ClientWidth then HScrollPosition := 0;
  if fContentHeight <= ClientHeight then VScrollPosition := 0;
  UpdateDims;
end;


constructor TThumbControl.Create(AOwner: TComponent);
var ff: TFontFinder;
begin
  inherited Create(AOwner);

  with GetControlClassDefaultSize do SetInitialBounds(0, 0, CX, CY);

  FURLList := TStringList.create;

  ff := TFontFinder.Create;
  Font.Name := ff.FindAFontFromDelimitedString('Trebuchet MS,Schumacher Clean');
  Font.size := 7;
  ff.free;

  fWindowCreated := false;
  DoubleBuffered := true;
  fThumbWidth := 80;
  fThumbHeight := 80;
  fUserThumbWidth := fThumbHeight;
  fUserThumbHeight := fThumbHeight;

  fContentWidth := GetControlClassDefaultSize.cx;
  fContentHeight := GetControlClassDefaultSize.cy;

  fThumbDist := 10;

  fLeftOffset := fThumbDist;
  fTopOffset := fThumbDist;
  FShowCaptions := true;
  fTextExtraHeight := 0;
  FShowPictureFrame := true;
  fPictureFrameBorder := StockBorderWidth;

  fMngr := TImageLoaderManager.Create;
  fMngr.OnLoadURL := @ImgLoadURL;
  fMngr.OnLoaded := @ImgLoaded;
  fAutoSort:=true;

  SmallStep := fThumbWidth;
  LargeStep := fThumbWidth * 4;

  fFrame := TBitmap.Create;
  fFrame.PixelFormat := pf32Bit;

  fDirectory := GetUserDir;
end;

destructor TThumbControl.Destroy;
begin
  FURLList.Free;
  fMngr.free;
  fFrame.free;
  inherited Destroy;
end;

procedure TThumbControl.DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy;
  const AXProportion, AYProportion: Double);
begin
  inherited;
  if AMode in [lapAutoAdjustWithoutHorizontalScrolling, lapAutoAdjustForDPI] then
  begin
    FUserThumbWidth := round(FUserThumbWidth * AXProportion);
    FUserThumbHeight := round(FUserThumbHeight * AYProportion);
    FThumbDist := round(FThumbDist * AXProportion);
    fTextExtraHeight := round(FTextExtraHeight * AYProportion);
    fLeftOffset := round(fLeftOffset * AXProportion);
    fTopOffset := round(fTopOffset * AYProportion);
  //  FPictureFrameBorder := round(FPictureFrameBorder * AXProportion);
    Arrange;
  end;
end;

function TThumbControl.GetDefaultColor(const DefaultColorType: TDefaultColorType): TColor;
begin
  if DefaultColorType = dctBrush then
    Result := clWindow
  else
    Result := clWindowText;
end;

procedure TThumbControl.UpdateDims;
begin
  if (VScrollInfo.nMax <> fContentHeight) or (VScrollInfo.nPage <> ClientHeight) then
  begin
    fVScrollInfo.nPage := ClientHeight;
    fVScrollInfo.nMax := fContentHeight;
    CanShowV := VScrollInfo.nMax > VScrollInfo.nPage;
    UpdateVScrollInfo;
  end;
  if (HScrollInfo.nMax <> fContentWidth) or (HScrollInfo.nPage <> ClientWidth) then
  begin
    fHScrollInfo.nPage := ClientWidth;
    fHScrollInfo.nMax := fContentWidth;
    CanShowH := HScrollInfo.nMax > HScrollInfo.nPage;
    UpdateHScrollInfo;
  end;
end;

function TThumbControl.ItemFromPoint(APoint: TPoint): TThreadedImage;
begin
  Result := fMngr.ItemFromPoint(Point(APoint.X + HScrollPosition, APoint.Y + VScrollPosition));
end;

procedure TThumbControl.LoadSelectedBitmap(ABitmap:TBitmap);
var fi:TFPMemoryImage;
itm:TThreadedImage;
begin
  itm:=fMngr.ActiveItem;
  if itm=nil then exit;
  fi:=TFPMemoryImage.create(0,0);
  fi.UsePalette:=false;
  try
    fi.LoadFromFile(UTF8ToSys(itm.URL));
    ABitmap.Assign(fi);
  finally
    fi.free;
  end;
end;


procedure TThumbControl.ImgLoadURL(Sender: TObject);
var Ext, Fn: string;
  Img, IRes: TFPMemoryImage;
  rdjpegthumb: TFPReaderJPEG;
  area: TRect;
  Strm: TStream;
begin
  Strm := nil;
  TThreadedImage(Sender).LoadState := lsError;
  Fn := TThreadedImage(Sender).URL;
  Ext := LowerCase(ExtractFileExt(LowerCase(Fn)));
  if (Ext = '.jpg') or (Ext = '.jpeg') then
  begin
    Img := TFPMemoryImage.Create(0, 0);
    Img.UsePalette := false;
    rdjpegthumb := TFPReaderJPEG.Create;
    rdjpegthumb.MinHeight := fThumbHeight;
    rdjpegthumb.MinWidth := fThumbWidth;
    try
      if Assigned(FOnLoadFile) then OnLoadFile(Sender, Fn, Strm);
      if Strm <> nil then
      begin
        Img.LoadFromStream(Strm, rdjpegthumb);
        Strm.free;
      end else Img.LoadFromFile(UTF8ToSys(Fn), rdjpegthumb);
      IRes := ThumbResize(Img, fThumbWidth, fThumbHeight, area);
      try
        CSImg.Acquire;
        if TThreadedImage(Sender).Image <> nil
          then
        begin
          TThreadedImage(Sender).Image.Assign(IRes);
          TThreadedImage(Sender).Area := Area;
        end;
      finally
        CSImg.Release;
      end;
    finally
      IRes.free;
      rdjpegthumb.free;
      Img.free;
    end;
  end else
  begin
    Img := TFPMemoryImage.Create(0, 0);
    Img.UsePalette := false;
    try
      if Assigned(FOnLoadFile) then OnLoadFile(Sender, Fn, Strm);
      if Strm <> nil then
      begin
        Img.LoadFromStream(Strm);
        Strm.free;
      end else Img.LoadFromFile(UTF8ToSys(Fn));
      IRes := ThumbResize(Img, fThumbWidth, fThumbHeight, area);
      try
        CSImg.Acquire;
        if TThreadedImage(Sender).Image <> nil then
        begin
          TThreadedImage(Sender).Image.Assign(IRes);
          TThreadedImage(Sender).Area := Area;
        end;
      finally
        CSImg.Release;
      end;
    finally
      IRes.free;
      Img.free;
    end;
  end;
  TThreadedImage(Sender).LoadState := lsLoading;
end;


procedure TThumbControl.ImgLoaded(Sender: TObject);
var aRect: TRect;
begin
  aRect := TThreadedImage(Sender).Rect;
  OffSetRect(aRect, -HScrollPosition, -VScrollPosition);
  InflateRect(ARect, 2, 2);
  InvalidateRect(Handle, @aRect, false);
end;

class function TThumbControl.GetControlClassDefaultSize: TSize;
begin
  Result.CX := 260;
  Result.CY := 140;
end;


procedure Register;
begin
  RegisterComponents('Misc', [TThumbControl]);
end;

initialization
{$I thumbctrl.lrs}
{$I images.lrs}
  frame := TPortableNetworkGraphic.create;
  frame.LoadFromLazarusResource('framecropab');
  //frame.saveToFile('framecropab.png');

finalization
  frame.free;

end.
