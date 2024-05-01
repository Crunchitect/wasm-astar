;; Handwritten WebAssembly for A* pathfinding Algorithm
;; By crunchi

(module
    ;; memory mapping
    ;; the maze: 1024 x 1024
    ;; 1 pixel = 1 byte
    ;; Block = 1
    ;; Path = 0
    (memory $maze 16)
    ;; Node is 16 bytes long
    ;; Node Spec
    ;; parent -> (u32*)
    ;; x, y, g, h -> u16
    ;; is_empty -> bool as u16
    ;; empty buffer -> u16 (00 00)
    (memory $open_list 64 256)
    (memory $closed_list 64 256)
    (memory $path 64 256)
    (memory $children 1)
    (global $width (mut i32) (i32.const 0))
    (global $height (mut i32) (i32.const 0))
    (global $open_list_index (mut i32) (i32.const 0))
    (global $closed_list_index (mut i32) (i32.const 0))
    (func $get_width (result i32)
        (global.get $width)
    )

    (func $set_width (param $val i32)
        (global.set $width (local.get $val))
    )

    (func $get_height (result i32)
        (global.get $height)
    )

    (func $set_height (param $val i32)
        (global.set $height (local.get $val))
    )

    ;; pixel is 8 bytes, mem[y*w+x]
    (func $get_pixel (param $w i32) (param $x i32) (param $y i32) (result i32)
        (i32.load8_u
            (memory $maze)
            (i32.add
                (i32.mul (local.get $w) (local.get $y))
                (local.get $x)
            )
        )
    )

    ;; mem[y*w+x] = v
    (func $set_pixel (param $w i32) (param $x i32) (param $y i32) (param $v i32)
        (i32.store8
            (memory $maze)
            (i32.add
                (i32.mul (local.get $w) (local.get $y))
                (local.get $x)
            )
            (local.get $v)
        )
    )

    ;; mem[i*8] - parent
    ;; mem[i*16+4] = x ; mem[i*16+6] = y ; mem[i*16+8] = g ; mem[i*16+10] = h ; mem[i*16+12] = f ; mem[i*16+14] = is_empty
    (func $push_open_list (param $parent i32) (param $x i32) (param $y i32) (param $g i32) (param $h i32) (param $f i32) (param $is_empty i32)
        (i32.store
            (memory $open_list)
            (i32.mul (global.get $open_list_index) (i32.const 8))
            (local.get $parent)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 4))
            (local.get $x)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 6))
            (local.get $y)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 8))
            (local.get $g)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 10))
            (local.get $h)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 12))
            (local.get $f)
        )
        (i32.store16
            (memory $open_list)
            (i32.add (i32.mul (global.get $open_list_index) (i32.const 16)) (i32.const 14))
            (local.get $is_empty)
        )
        (global.set $open_list_index (i32.add (global.get $open_list_index) (i32.const 1)))
    )
    
    ;; mem[i*8] - parent
    ;; mem[i*16+4] = x ; mem[i*16+6] = y ; mem[i*16+8] = g ; mem[i*16+10] = h ; mem[i*16+12] = f ; mem[i*16+14] = is_empty; 
    (func $push_closed_list (param $parent i32) (param $x i32) (param $y i32) (param $g i32) (param $h i32) (param $f i32) (param $is_empty i32)
        (i32.store
            (memory $closed_list)
            (i32.mul (global.get $closed_list_index) (i32.const 8))
            (local.get $parent)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 4))
            (local.get $x)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 6))
            (local.get $y)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 8))
            (local.get $g)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 10))
            (local.get $h)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 12))
            (local.get $f)
        )
        (i32.store16
            (memory $closed_list)
            (i32.add (i32.mul (global.get $closed_list_index) (i32.const 16)) (i32.const 14))
            (local.get $is_empty)
        )
        (global.set $closed_list_index (i32.add (global.get $closed_list_index) (i32.const 1)))
    )

    (func $get_open_list_parent (param $i i32) (result i64)
        (i64.load32_u
            (memory $open_list)
            (i32.mul (local.get $i) (i32.const 8))
        )
    )

    (func $get_open_list_x (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 4))
        )
    )

    (func $get_open_list_y (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 6))
        )
    )

    (func $get_open_list_g (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 8))
        )
    )

    (func $get_open_list_h (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 10))
        )
    )
    
    (func $get_open_list_f (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 12))
        )
    )

    (func $get_open_list_is_empty (param $i i32) (result i32)
        (i32.load16_u
            (memory $open_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 14))
        )
    )

    (func $get_closed_list_parent (param $i i32) (result i64)
        (i64.load32_u
            (memory $closed_list)
            (i32.mul (local.get $i) (i32.const 8))
        )
    )

    (func $get_closed_list_x (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 4))
        )
    )

    (func $get_closed_list_y (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 6))
        )
    )

    (func $get_closed_list_g (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 8))
        )
    )

    (func $get_closed_list_h (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 10))
        )
    )
    
    (func $get_closed_list_f (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 12))
        )
    )

    (func $get_closed_list_is_empty (param $i i32) (result i32)
        (i32.load16_u
            (memory $closed_list)
            (i32.add (i32.mul (local.get $i) (i32.const 16)) (i32.const 14))
        )
    )

    (func $drop_open_list
        (global.set $open_list_index (i32.sub (global.get $open_list_index) (i32.const 1)))
    )

    (func $drop_closed_list
        (global.set $closed_list_index (i32.sub (global.get $closed_list_index) (i32.const 1)))
    )

    (func $dump_open_list
        (global.set $open_list_index (i32.const 0))
    )

    (func $dump_closed_list
        (global.set $closed_list_index (i32.const 0))
    )

    (func $pop_open_list (param $i i32)
        (local $j i32)
        (if (i32.eq (local.get $i) (i32.sub (global.get $open_list_index) (i32.const 1)))
            (then
                (local.set $j (i32.add (local.get $i) (i32.const 1)))
                loop $o_pop
                    (i64.store
                        (memory $open_list)
                        (i32.mul (i32.add (local.get $j) (i32.const 1)) (i32.const 2))
                        (i64.load
                            (memory $open_list)
                            (i32.mul (local.get $j) (i32.const 2))
                        )
                    )
                    (i64.store
                        (memory $open_list)
                        (i32.add (i32.mul (i32.add (local.get $j) (i32.const 1)) (i32.const 2)) (i32.const 1))
                        (i64.load
                            (memory $open_list)
                            (i32.add (i32.mul (local.get $j) (i32.const 2)) (i32.const 1))
                        )
                    )
                    (local.set $j (i32.add (local.get $j) (i32.const 1)))
                    (br_if $o_pop (i32.lt_u (local.get $j) (global.get $open_list_index)))
                end
            )
        )
    )

    (func $astar (param $start_x i32) (param $start_y i32) (param $end_x i32) (param $end_y i32)
        ;; current_node = Node()
        (local $current_node_parent i64) (local $current_node_x i32) (local $current_node_y i32) (local $current_node_g i32) (local $current_node_h i32) (local $current_node_f i32) (local $current_node_e i32)
        ;; path_node = Node()
        (local $path_parent i64) (local $path_x i32) (local $path_y i32) (local $path_g i32) (local $path_h i32) (local $path_f i32) (local $path_e i32)
        ;; current_index
        (local $current_index i32)
        ;; tmp
        (local $tmp i32)
        (local $children_index i32)
        (local $dir i32) (local $b0 i32) (local $b1 i32)
        ;; child_node
        (local $child_x i32)
        (local $child_y i32)
        (local $child_f i32)
        (local $child_g i32)
        (local $child_h i32)
        (local $child_e i32)
        (local $child_p i32)
        ;; is_in_list
        (local $in_o i32) (local $in_c i32)
        ;; tmp2
        (local $tmp2 i32)

        (call $dump_open_list)
        (call $dump_closed_list)

        ;; open_list.append(start)
        (call $push_open_list
            (i32.const 0)
            (local.get $start_x)
            (local.get $start_y)
            (i32.const 0)
            (i32.const 0)
            (i32.const 0)
            (i32.const 1)
        )
        ;; while len(open_list) > 0
        loop $open_list_loop
            ;; current_node = open_list[0]
            (local.set $current_node_parent (call $get_open_list_parent (i32.const 0)))
            (local.set $current_node_x (call $get_open_list_x (i32.const 0)))
            (local.set $current_node_y (call $get_open_list_y (i32.const 0)))
            (local.set $current_node_f (call $get_open_list_f (i32.const 0)))
            (local.set $current_node_g (call $get_open_list_g (i32.const 0)))
            (local.set $current_node_h (call $get_open_list_h (i32.const 0)))
            (local.set $current_node_e (call $get_open_list_is_empty (i32.const 0)))
            ;; current_index = 0
            (local.set  $current_index (i32.const 0))
            (local.set  $tmp (i32.const 0))
            ;; for i in len(open_list)
            loop $l0
                ;; if open_list[i].f < current_node.f
                (if (i32.lt_u (call $get_open_list_f (local.get $tmp)) (local.get $current_node_f))
                    (then
                        ;; current_node = open_list[i]
                        (local.set $current_node_parent (call $get_open_list_parent (local.get $tmp)))
                        (local.set $current_node_x (call $get_open_list_x (local.get $tmp)))
                        (local.set $current_node_y (call $get_open_list_y (local.get $tmp)))
                        (local.set $current_node_f (call $get_open_list_f (local.get $tmp)))
                        (local.set $current_node_g (call $get_open_list_g (local.get $tmp)))
                        (local.set $current_node_h (call $get_open_list_h (local.get $tmp)))
                        (local.set $current_node_e (call $get_open_list_is_empty (local.get $tmp)))
                        ;; current_index = i
                        (local.set $current_index (local.get $tmp))
                    )
                )
                ;; open_list.pop(current_index)
                (call $pop_open_list (local.get $current_index))
                ;; close_list.append(node)
                (call $push_closed_list
                    (i32.wrap_i64 (local.get $current_node_parent))
                    (local.get $current_node_x)
                    (local.get $current_node_y)
                    (local.get $current_node_g)
                    (local.get $current_node_h)
                    (local.get $current_node_f)
                    (local.get $current_node_e)
                )

                ;; if current_node = end_node
                (if (i32.and (i32.eqz (local.get $current_node_x) (local.get $end_x)) (i32.eqz (local.get $current_node_y) (local.get $end_y)))
                    (then
                        (local.set $tmp (i32.const 0))
                        ;; path_node = current_node
                        (local.set $path_parent (local.get $current_node_parent))
                        (local.set $path_x (local.get $current_node_x) )
                        (local.set $path_y (local.get $current_node_y) )
                        (local.set $path_f (local.get $current_node_f) )
                        (local.set $path_g (local.get $current_node_g) )
                        (local.set $path_g (local.get $current_node_h) )
                        (local.set $path_e (local.get $current_node_e) )
                        ;; while !is_empty
                        loop $l1
                            ;; path.append(position)
                            (i32.store16 (memory $path) (i32.mul (local.get $tmp) (i32.const 2)) (local.get $path_x))
                            (i32.store16 (memory $path) (i32.add (i32.mul (local.get $tmp) (i32.const 2)) (i32.const 1)) (local.get $path_y))
                            ;; path = path.parent
                            (local.set $path_parent (call $get_closed_list_parent (i32.wrap_i64 (local.get $path_parent))))
                            (local.set $path_x (call $get_closed_list_x (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $path_y (call $get_closed_list_y (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $path_g (call $get_closed_list_g (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $path_h (call $get_closed_list_h (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $path_f (call $get_closed_list_f (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $path_e (call $get_closed_list_is_empty (i32.wrap_i64 (local.get $path_parent))) )
                            (local.set $tmp (i32.add (local.get $tmp) (i32.const 1)))
                            (br_if $l1 (i32.eqz (local.get $path_e) (i32.const 0)))
                            drop
                        end
                    )
                )

                ;; children = []
                (local.set $children_index (i32.const 0))
                ;; for (b0, b1) in [(0, -1), (0, 1), (1, 0), (-1, 0)]
                (local.set $dir (i32.const 0))
                loop $l1
                    (local.set $b0 (i32.div_u (i32.and (i32.const 2) (local.get $dir)) (i32.const 2)))
                    (local.set $b1 (i32.and (i32.const 1) (local.get $dir)))
                    (if (i32.eqz (local.get $b0) (local.get $b1))
                        (then
                            (local.set $b1 (i32.const -1))
                        )
                    )

                    (local.set $child_x (i32.add (local.get $current_node_x) (local.get $b0)))
                    (local.set $child_y (i32.add (local.get $current_node_y) (local.get $b1)))
                    ;; if out of bounds
                    (if (i32.add (i32.lt_s (local.get $child_x) (i32.const 0)) (i32.add (i32.gt_s (local.get $child_x) (global.get $width)) (i32.add (i32.lt_s (local.get $child_y) (i32.const 0)) (i32.gt_s (local.get $child_y) (global.get $height)))))
                        (then ;; continue                       
                        )
                        (else
                            ;; if walkable
                            (
                            if (call $get_pixel (global.get $width) (local.get $child_x) (local.get $child_y))
                            (then
                                ;; if in closed list
                                (local.set $in_c (i32.const 0))
                                (local.set $tmp2 (i32.const 0))
                                loop $l2
                                    (if (i32.and (
                                        i32.eq (local.get $child_x) (call $get_closed_list_x (local.get $tmp2))
                                    ) (
                                        i32.eq (local.get $child_y) (call $get_closed_list_y (local.get $tmp2))
                                    )) (then (local.set $in_c (i32.const 1))))
                                    (local.set $tmp2 (local.get $tmp2) (i32.const 1))
                                    (br_if $l2 (i32.lt_u (local.get $tmp2) (global.get $closed_list_index)))
                                    drop
                                end
                                (if (local.get $in_c)
                                    (then )
                                    (else 
                                        (local.set $child_g (i32.add (local.get $current_node_g) (i32.const 1)))
                                        (local.set $child_h (i32.add 
                                        (i32.mul (i32.sub (local.get $end_x) (local.get $child_x)) (i32.sub (local.get $end_x) (local.get $child_x)))
                                        (i32.mul (i32.sub (local.get $end_y) (local.get $child_y)) (i32.sub (local.get $end_y) (local.get $child_y)))
                                        ))
                                        (local.set $child_f (i32.add (local.get $child_g) (local.get $child_h)))
                                        ;; if in open list
                                        (local.set $in_o (i32.const 0))
                                        (local.set $tmp2 (i32.const 0))
                                        loop $l2
                                            (if (i32.and (i32.and (
                                                i32.eq (local.get $child_x) (call $get_closed_list_x (local.get $tmp2))
                                            ) (
                                                i32.eq (local.get $child_y) (call $get_closed_list_y (local.get $tmp2))
                                            )) (i32.gt_s (local.get $child_g) (call $get_closed_list_g (local.get $tmp2)))) 
                                            (then (local.set $in_o (i32.const 1))))
                                            (local.set $tmp2 (local.get $tmp2) (i32.const 1))
                                            (br_if $l2 (i32.lt_u (local.get $tmp2) (global.get $open_list_index)))
                                            drop
                                        end
                                        (if (local.get $tmp2)
                                            (then )
                                            (else 
                                                (call $push_open_list
                                                    (i32.sub (global.get $closed_list_index) (i32.const 1))
                                                    (local.get $child_x)
                                                    (local.get $child_y)
                                                    (local.get $child_g)
                                                    (local.get $child_h)
                                                    (local.get $child_f)
                                                    (i32.const 1)
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                            )

                        )
                    )

                    (local.set $dir (i32.add (local.get $dir) (i32.const 1)))
                    (br_if $l1 (i32.lt_u (local.get $dir) (i32.const 4)))
                    drop
                end

                (local.set $tmp (i32.add (local.get $tmp) (i32.const 1)))
                (br_if $l0 (i32.lt_u (local.get $tmp) (global.get $open_list_index)))
                drop
                drop
            end
            (br_if $open_list_loop (i32.gt_u (global.get $open_list_index) (i32.const 0)))
        end
    )

    (export "get_width" (func $get_width))
    (export "set_width" (func $set_width))
    (export "get_height" (func $get_height))
    (export "set_height" (func $set_height))

    (export "get_pixel" (func $get_pixel))
    (export "set_pixel" (func $set_pixel))

    (export "push_o" (func $push_open_list))
    (export "push_c" (func $push_closed_list))
    (export "drop_o" (func $drop_open_list))
    (export "drop_c" (func $drop_closed_list))
    (export "dump_o" (func $dump_open_list))
    (export "dump_c" (func $dump_closed_list))

    (export "index_o_p" (func $get_open_list_parent))
    (export "index_o_x" (func $get_open_list_x))
    (export "index_o_y" (func $get_open_list_y))
    (export "index_o_g" (func $get_open_list_g))
    (export "index_o_h" (func $get_open_list_h))
    (export "index_o_f" (func $get_open_list_f))
    (export "index_o_e" (func $get_open_list_is_empty))
    (export "index_c_p" (func $get_closed_list_parent))
    (export "index_c_x" (func $get_closed_list_x))
    (export "index_c_y" (func $get_closed_list_y))
    (export "index_c_g" (func $get_closed_list_g))
    (export "index_c_h" (func $get_closed_list_h))
    (export "index_c_f" (func $get_closed_list_f))
    (export "index_c_e" (func $get_closed_list_is_empty))

    (export "maze" (memory $maze))
    (export "path" (memory $path))
    (export "open_list" (memory $open_list))
    (export "closed_list" (memory $closed_list))

    (export "astar" (func $astar))
)