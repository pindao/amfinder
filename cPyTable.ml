(* CastANet - cPyTable.ml *)

open CExt

type pytable = {
  py_label : string;                    (* Base name without extension.    *)
  py_level : CLevel.t;                  (* Annotation level (from header). *)
  py_header : char list;                (* Header character order.         *)
  py_matrix : float list Ext_Matrix.t;  (* Probabilities.                  *)
}

let label t = t.py_label
let level t = t.py_level
let header t = t.py_header
let matrix t = t.py_matrix

let ensure_consistency f = function
  | [] -> [] (* nothing to be checked here. *)
  | hdr :: rem as dat -> let n = f hdr in
    assert (List.for_all (fun x -> f x = n) rem);
    dat

let s2i = int_of_string
let s2f = float_of_string

let import tsv =
  assert (Sys.file_exists tsv);
  let valid_input_list = Ext_File.read tsv
    |> String.split_on_char '\n'
    |> List.map (String.split_on_char '\t')
    |> ensure_consistency List.length in
  match valid_input_list with
  | [] -> None (* Nothing to load! *)
  | hdr :: dat ->
    let chars = match hdr with
      | _ :: _ :: z -> List.map (fun s -> s.[0]) z
      | _ -> assert false
    and probs = List.map (function
      | x :: y :: z -> (s2i x, s2i y), List.map s2f z
      | _ -> assert false) dat
    and label = Filename.(basename tsv |> remove_extension)
    in Some (label, chars, probs)
      
let to_matrix (py_label, py_header, probs) =
  let py_level = CLevel.of_list py_header in
  let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 probs + 1
  and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 probs + 1 in
  let py_matrix = Ext_Matrix.init nr nc (fun r c -> List.assoc (r, c) probs) in
  {py_label; py_level; py_header; py_matrix}

let load ~tsv = Option.map to_matrix (import tsv)
