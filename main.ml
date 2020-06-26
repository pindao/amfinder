(* main.ml *)

open CExt
open Printf

let may_show_layer (widget : GButton.radio_tool_button) () =
  if widget#get_active then CDraw.active_layer ()

let _ =
  Printexc.record_backtrace true;
  print_endline "castanet-annotation-editor version 1.0";
  if Array.length Sys.argv = 2 && Sys.file_exists Sys.argv.(1) then (
    CEvent.mouse_pointer ();
    CEvent.keyboard ();    
    CGUI.main_window#show ();
    tagger_time CDraw.load Sys.argv.(1);
    CEvent.icons ();
    List.iter (fun (_, radio) ->
      radio#connect#toggled ~callback:(may_show_layer radio); ()
    ) CGUI.Layers.radios;
    CGUI.Layers.master#connect#toggled
      ~callback:(may_show_layer CGUI.Layers.master);
    may_show_layer CGUI.Layers.master ();
    CDraw.GUI.magnified_view ();
    CGUI.status#set_label (CImage.digest (CDraw.curr_image ()));
    GMain.main ()
  ) else prerr_endline "Usage: castanet-tagger <image>"
