unit EventInterceptor;

interface

uses Classes;

type
  TEventInterceptor = class(TComponent)
  private
    FEventName : string;
    FComponent : TComponent;
    originalEvent : TMethod;
    procedure HandleEvent;

    class procedure RecurseComponents(Component: TComponent; ExaminedComponents: TList);
    constructor Create(Component: TComponent; EventName:string; OriginalEvent:TMethod);
  public
    property EventName: string read FEventName;
    property Component: TComponent read FComponent;
  end;

  TEventInterceptorLogger = procedure(EventInterceptor: TEventInterceptor);

procedure AddEventInterceptors(Component: TComponent);
procedure DefaultEventInterceptorLogger(EventInterceptor: TEventInterceptor);

var
  GlobalEventInterceptorLogger: TEventInterceptorLogger;

implementation

uses TypInfo, SysUtils, Windows, Dialogs, Variants;

procedure DefaultEventInterceptorLogger(EventInterceptor: TEventInterceptor);
begin
  // do nothing
end;

constructor TEventInterceptor.Create(Component: TComponent; EventName: string; OriginalEvent: TMethod);
begin
  inherited Create(Component);
  self.FComponent := Component;
  self.FEventName := EventName;
  self.originalEvent := OriginalEvent;
end;

procedure TEventInterceptor.HandleEvent;
asm
  // Call event logger...
  PUSHAD
  CALL GlobalEventInterceptorLogger
  POPAD

  // Jump to original code
  PUSH [EAX].originalEvent.Code
  MOV EAX, [EAX].originalEvent.Data
  RET
end;

class procedure TEventInterceptor.RecurseComponents(Component: TComponent; ExaminedComponents: TList);
var
  interceptor: TEventInterceptor;
  TypeInfo: PTypeInfo;
  TypeData: PTypeData;
  PropList: PPropList;
  i : integer;
  aMethod: TMethod;
begin
  ExaminedComponents.Add(Component);

  TypeInfo := Component.ClassInfo;
  TypeData := GetTypeData(TypeInfo);

  new(PropList);
  try
    GetPropInfos(TypeInfo, PropList);
    for i := 0 to Pred(TypeData^.PropCount) do begin
      if (PropList^[i]^.PropType^.Kind = tkMethod) then begin
        aMethod := GetMethodProp(TObject(Component), PropList^[i]);
        if aMethod.Code <> nil then begin
          interceptor := TEventInterceptor.Create(Component, PropList^[i]^.Name, aMethod);

          aMethod.Data := interceptor;
          aMethod.Code := @TEventInterceptor.HandleEvent;
          SetMethodProp(TObject(Component), PropList^[i], aMethod);
        end;
      end;
    end;
  finally
    Dispose(PropList);
  end;

  for i := 0 to Pred(Component.ComponentCount) do
    if ExaminedComponents.IndexOf(Component.Components[i]) = -1 then
      RecurseComponents(Component.Components[i], ExaminedComponents);
end;

procedure AddEventInterceptors(Component:TComponent);
var
  examinedObjects: TList;
begin
  examinedObjects := TList.Create;
  try
    TEventInterceptor.RecurseComponents(Component, examinedObjects);
  finally
    examinedObjects.Free;
  end;
end;

initialization
  GlobalEventInterceptorLogger := DefaultEventInterceptorLogger;

end.
