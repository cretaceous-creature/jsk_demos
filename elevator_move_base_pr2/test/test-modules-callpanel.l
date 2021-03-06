#!/usr/bin/env roseus

(load "unittest.l")
(ros::load-ros-manifest "elevator_move_base_pr2")
(load "package://pr2eus/pr2-interface.l")
(load "package://elevator_move_base_pr2/src/posedetectiondb-client.l")
(load "package://elevator_move_base_pr2/src/elevator-move-base-main.l")
(ros::roseus "test_modules_callpanel")

(init-unit-test)

(deftest test-modules-callpanel ()
  (ros::advertise "visualization_marker" visualization_msgs::Marker)
  (ros::advertise "view_target" geometry_msgs::PointStamped 1)
  (pr2)
  (setq *ri* (instance pr2-interface :init))
  (setq count 0
	*m* nil
	*panel* (instance elevator_call_panel_eng2-object :init
			  :name "elevator_call_panel")
	button (find "down" (send *panel* :button) :test #'equal
		     :key #'(lambda(x)(send x :name)))
	marker (sphere->marker-msg (make-sphere 50)
		 (instance std_msgs::header :init :frame_id "/world")))
  ;; panel pose
  (setq client (instance posedetectiondb-client :init *panel*
			 :fixed-frame "/world"
			 :topic "/narrow_stereo/left/ObjectDetection"))
  (ros::subscribe "light_button" std_msgs::float32 #'(lambda(m)(setq *m* m)))
  ;;
  (while (and (< count 100) (not (and *m* (< 1.0 (send *m* :data)))))
    (ros::spin-once)
    ;; set button area
    (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
    (send *pr2* :angle-vector (send *ri* :state))
    (send marker :pose (ros::coords->tf-pose (send button :copy-worldcoords)))
    (send marker :color (vector->rgba #(0 0 1) 1)) ;; blue
    (ros::publish "visualization_marker" marker)
    (set-view-target (send button :copy-worldcoords)
		     (send *pr2* :wide_stereo-left)
		     "wide_stereo_optical_frame")
    ;; get button state
    (unix::usleep (* 100 1000)))
  ;; finish and check
  (send marker :color (vector->rgba #(1 0 0) 1)) ;; red
  (ros::publish "visualization_marker" marker)
  (assert *m*
	  "detector node returns result")
  (assert (and *m* (< 1.0 (send *m* :data)))
	  "button light has detected successfully")
  (unix::sleep 15) ;; for making video
  )

(run-all-tests)

(exit)
