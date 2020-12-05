(* The Automated Mycorrhiza Finder version 1.0 - amfSurface.ml *)

open Scanf

type edge = int
type color = string

let parse_html_color =
    let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
    fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

let pi = acos (-1.0)
let two_pi = 2.0 *. pi

let initialize color edge =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let r, g, b, a = parse_html_color color in
    Cairo.set_source_rgba t r g b a;
    t, surface

module Create = struct
    let rectangle ~width ~height ~color () =
        assert (width > 0 && height > 0);
        let surface = Cairo.Image.(create ARGB32 ~w:width ~h:height) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float width) ~h:(float height);
        Cairo.fill t;
        Cairo.stroke t;
        t, surface

    let square ~edge ~color () = rectangle ~width:edge ~height:edge ~color ()
end

let up_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.1 *. edge in
    let yini = frac and xini = edge /. 2.0 in
    let size =  0.48 *. xini in
    Cairo.move_to t xini yini;
    Cairo.line_to t (xini -. size) (edge -. frac);
    Cairo.line_to t (xini +. size) (edge -. frac);
    Cairo.fill t;
    Cairo.stroke t;
    surface


let down_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.4 *. edge in
    let yini = edge -. frac and xini = edge /. 2.0 in
    let size =  0.3 *. xini in 
    Cairo.move_to t xini yini;
    Cairo.line_to t (xini -. size) frac;
    Cairo.line_to t (xini +. size) frac;
    Cairo.fill t;
    Cairo.stroke t;
    surface


let right_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.4 *. edge in
    let xini = edge -. frac and yini = edge /. 2.0 in
    let size =  0.3 *. yini in 
    Cairo.move_to t xini yini;
    Cairo.line_to t frac (yini -. size);
    Cairo.line_to t frac (yini +. size);
    Cairo.fill t;
    Cairo.stroke t;
    surface


let circle ?(margin = 2.0) color edge =
    let t, surface = initialize color edge in
    let edge = float edge -. margin in
    let radius = 0.5 *. edge in
    let centre = 0.5 *. margin +. radius in
    Cairo.arc t centre centre ~r:radius ~a1:0.0 ~a2:two_pi;
    Cairo.fill t;
    Cairo.stroke t;
    surface


let solid_square ?sym ?(margin = 2.0) color edge =
    let t, surface = initialize color edge in
    let edge = float edge -. margin in
    Cairo.rectangle t (0.5 *. margin) (0.5 *. margin) ~w:edge ~h:edge;
    Cairo.fill t;
    Cairo.stroke t;
    Option.iter (fun sym ->
        Cairo.set_source_rgba t 1.0 1.0 1.0 1.0;
        Cairo.select_font_face t "Arial" ~weight:Cairo.Bold;
        Cairo.set_font_size t (if sym = "×" then 22.0 else 16.0);
        let te = Cairo.text_extents t sym in
        Cairo.move_to t
            (0.5 *. margin +. 0.5 *. edge -. te.Cairo.x_bearing -. 0.5 *. te.Cairo.width) 
            (0.5 *. margin +. 0.5 *. edge -. te.Cairo.y_bearing -. 0.5 *. te.Cairo.height);
        Cairo.show_text t sym;
    ) sym;
    surface


let empty_square ?(line = 5.0) color edge =
    let t, surface = initialize color edge in
    Cairo.set_line_width t line;
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.stroke t;
    surface


let prediction_palette ?(step = 12) colors edge =
    let len = Array.length colors in
    let surface = Cairo.Image.(create ARGB32 ~w:(step * len + 100) ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_NONE;
    Array.iteri (fun i color ->
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t (float (step * i + 50)) 0.0
            ~w:(float step)
            ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
    ) colors;
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    Cairo.select_font_face t "Arial" ~slant:Cairo.Italic;
    Cairo.set_font_size t 14.0;
    Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
    let te = Cairo.text_extents t "ggg" in
    Cairo.move_to t 
        (50.0 -. te.Cairo.width -. 5.0)
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "low";
    Cairo.move_to t
        (float (50 + step * len + 5))
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "high";
    surface

let transparency = "B0"

let annotation_legend symbs colors =
    assert List.(length symbs = length colors);
    let len = List.length colors in
    let margin = 8 in
    let w = 140 * len + 2 * margin and h = 30 + 2 * margin in
    let surface = Cairo.Image.(create ARGB32 ~w ~h) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    Cairo.set_source_rgba t 0.4 0.4 0.4 1.0;
    Cairo.rectangle t 0.0 0.0 ~w:(float w) ~h:(float h);
    Cairo.stroke t;
    let index = ref 0 in
    Cairo.select_font_face t "Arial";
    Cairo.set_font_size t 14.0;
    let te = Cairo.text_extents t "M" in
    List.iter2 (fun symb color ->
        let r, g, b, a = parse_html_color (color ^ transparency) in
        Cairo.set_source_rgba t r g b a;
        let x = float (margin + 140 * !index) in
        Cairo.arc t (x +. 15.0) (float margin +. 15.0) ~r:15.0 ~a1:0.0 ~a2:(2. *. acos(-1.0));
        Cairo.fill t;
        Cairo.stroke t;
        Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
        let x = x +. 32.0 and y = float margin +. 15.0 +. te.Cairo.height /. 2.0 in
        Cairo.move_to t x y;
        Cairo.show_text t symb;
        incr index
    ) symbs colors;
    surface

let pie_chart ?(margin = 2.0) prob_list colors edge =
    let t, surface = initialize "#ffffffff" edge in
    let edge = float edge -. margin in
    let radius = 0.5 *. edge in
    let from = ref 0.0 in
    List.iter2 (fun x clr ->
        let rad = two_pi *. x in  
        Cairo.move_to t radius radius;
        let a2 = !from +. rad in
        let centre = 0.5 *. margin +. radius in
        Cairo.arc t centre centre ~r:radius ~a1:!from ~a2;
        from := a2;
        Cairo.Path.close t;
        let r, g, b, a = parse_html_color (clr ^ "90") in
        Cairo.set_source_rgba t r g b a;
        Cairo.fill t;
        Cairo.stroke t;
    ) prob_list colors;
    surface

module Dir = struct
    let top ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = parse_html_color foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge /. 2.0) 0.0;
        Cairo.line_to t 0.0 (float edge);
        Cairo.line_to t (float edge) (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let bottom ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = parse_html_color foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge /. 2.0) (float edge);
        Cairo.line_to t 0.0 0.0;
        Cairo.line_to t (float edge) 0.0;
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let left ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = parse_html_color foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t 0.0 (float edge /. 2.0);
        Cairo.line_to t (float edge) 0.0;
        Cairo.line_to t (float edge) (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let right ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = parse_html_color foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge) (float edge /. 2.0);
        Cairo.line_to t 0.0 0.0;
        Cairo.line_to t 0.0 (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface
end
