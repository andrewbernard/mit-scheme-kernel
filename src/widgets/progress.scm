(define (make-progress-state style layout)
  `((value . 0)
    (min . 0)
    (max . 100)
    (step . 1)
    (description . "")
    (orientation . "horizontal")
    (disabled . #f)
    (style . ,(make-widget-model style))
    (layout . ,(make-widget-model layout))
    (_dom_classes . #())
    (continuous_update . #t)))

(define (make-progress)
  (let ((layout (make-widget "LayoutModel" "LayoutView"))
        (style (make-widget "ProgressStyleModel" "StyleView")))
    (let ((state (make-progress-state layout style)))
      (let ((widget (make-widget "ProgressModel" "ProgressView")))
        (display-widget widget)
        widget))))

(define set-progress-value! (widget-updater 'value integer?))
(define set-progress-min! (widget-updater 'min integer?))
(define set-progress-max! (widget-updater 'max integer?))
(define set-progress-step! (widget-updater 'step integer?))
(define set-progress-description! (widget-updater 'description string?))
(define set-progress-orientation! (widget-updater 'orientation string?))
(define set-progress-disabled! (widget-updater 'disabled boolean?))
