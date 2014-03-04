EventInterceptor
================

EventInterceptor is a Delphi unit that allows you to log any type of Delphi event on TComponent. It is based on the works of [delphieventlogger](https://code.google.com/p/delphieventlogger/) with the difference that EventInterceptor can log any type of Delphi event, not just TNotifyEvents like delphieventlogger does.

This version of EventInterceptor is only tested with Delphi 2007.

Usage
=====
There is one procedure which you need to know:

```delphi
procedure AddEventInterceptors(Component: TComponent);
```
  
After calling it, EventInterceptor will log any event that happens on the supplied component and its sub components recursively. By default the logging procedure does nothing, so you have to set the global variable GlobalEventInterceptorLogger to a logging procedure which will log the output to a file or to stdout, whatever makes sense for you:
  
```delphi
procedure LogToStdout(EventInterceptor: TEventInterceptor);
begin
  WriteLn(EventInterceptor.Component.Name,
          EventInterceptor.Component.ClassName,
          EventInterceptor.EventName);
end;

procedure TSomeComponent.Create(Sender: TObject);
begin
  AddEventInterceptors(self);
  GlobalEventInterceptorLogger := LogToStdout;
end;
```
