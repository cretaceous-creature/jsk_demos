(load "package://detect_cans_in_fridge_201202/euslisp/main.l")

(defvar *tf-listener* (instance ros::transform-listener :init))

(defun test-go-to-fridge ()
  (if (not (boundp '*obj*)) (init))

  ;(setq *orig-pose* (send *ri* :state :worldcoords))

  (pr2-tuckarm-pose :rarm)
  ;(goto-front-of-fridge)

  ;; copy from open-fridge-door
  (let (ret
	(idealcds (make-coords :pos (float-vector 733.757 135.013 1092.946)
			       :rpy (float-vector 0.002 0.059 -0.019)))
	(diffcds (make-coords :pos (float-vector 10000 10000 10000)))
        footcds)
    (dotimes (i 10 nil)
      ;; finding handle position
      (when (check :type "fridge") ;; need detection fail check
        ;; opening door
        (ros::ros-fatal "pr2 position ~9,3f ~9,3f ~9,3f"
                        (elt (send *pr2* :worldpos) 0)
                        (elt (send *pr2* :worldpos) 1)
                        (rad2deg (elt (car (rpy-angle (send *pr2* :worldrot))) 0)))
        (ros::ros-fatal "obj position ~9,3f ~9,3f ~9,3f"
                        (elt (send *obj* :worldpos) 0)
                        (elt (send *obj* :worldpos) 1)
                        (rad2deg (elt (car (rpy-angle (send *obj* :worldrot))) 0)))
        (ros::ros-fatal "ide position ~9,3f ~9,3f ~9,3f"
                        (elt (send idealcds :worldpos) 0)
                        (elt (send idealcds :worldpos) 1)
                        (rad2deg (elt (car (rpy-angle (send idealcds :worldrot))) 0)))

        (setq diffcds (send (send *obj* :copy-worldcoords)
                            :transform (send idealcds :inverse-transformation)
                            :world)) ;; pr2 is located at origin and obje' reference coords is pr2

        (ros::ros-fatal "diff coords  ~9,3f ~9,3f ~9,3f < go-to-unsafe~%"
                        (/ (elt (send diffcds :worldpos) 0) 1000.0)
                        (/ (elt (send diffcds :worldpos) 1) 1000.0)
                        (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0)))
        (send *ri* :go-pos-unsafe
              (/ (elt (send diffcds :worldpos) 0) 1000.0)
              (/ (elt (send diffcds :worldpos) 1) 1000.0)
              (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0)))
        (unix::usleep (* 2 1000 1000)) ;; wait

        (when (send  *tf-listener* :wait-for-transform "/map" "/base_footprint" (ros::time-now) 1)
          (setq footcds (send *tf-listener* :lookup-transform "/map" "/base_footprint" (ros::time 0))))
        (when footcds
          (ros::ros-fatal "footf coords ~9,3f ~9,3f ~9,3f~%"
                          (elt (send footcds :worldpos) 0)
                          (elt (send footcds :worldpos) 1)
                          (rad2deg (elt (car (rpy-angle (send footcds :worldrot))) 0))))

        )
      ))
  ;(send *ri* :move-to *orig-pose*))
  )

(warn ";;~%")
(warn ";;~%")
(warn ";; (init)~%")
(warn ";; (test-go-to-fridge)~%")