(define comm-version "~2.1.4")
(define comm-widget-name "jupyter.widget")
(define comm-module "jupyter-js-widgets")

(define widget-links '())

(define (make-widget-model widget)
  (string-append "IPY_MODEL_" (comm-id (widget-comm widget))))

(define (make-widget-data model view #!optional state)
  (fold-right
    cons
    (if (default-object? state) '() state)
    `((_view_module . ,comm-module)
      (_view_name . ,view)
      (msg_throttle . 1)
      (_dom_classes . #())
      (_model_module . ,comm-module)
      (_model_module_version . ,comm-version)
      (_view_module_version . ,comm-version)
      (_model_name . ,model))))

(define (make-widget model view #!optional state)
  (let ((state (if (default-object? state) '() state)))
    (let ((data (make-widget-data model view state)))
      (let ((comm (open-comm session comm-widget-name data)))
        (let ((widget (initialize-widget (comm-id comm) comm model view state)))
          (session-add-comm! session comm)
          (session-add-widget! session widget)
          widget)))))

(define (display-widget widget)
  (let ((comm (widget-comm widget)))
    (send-comm-msg comm '((method . "display")))
    ((session-pub (comm-session comm))
      "display_data"
      `((transient)
        (data
	        (application/vnd.jupyter.widget-view+json
	          (model_id . ,(comm-id comm))))
	      (metadata)))))

(define (update-widget! widget state)
  (let ((comm (widget-comm widget)))
    (send-comm-msg comm `((method . "update") (state . ,state)))
    (set-widget-state! widget (merge-states (widget-state widget) state))))

(define ((widget-updater property #!optional predicate) widget value)
  (assert (or (default-object? predicate) (predicate value)))
  (update-widget! widget (list (cons property value))))

(define set-widget-value! (widget-updater 'value))










(define make-handler cons)
(define handler-name car)
(define handler-effector cdr)
(define (handler? handler)
  (and
    (pair? handler)
    (symbol? (handler-name handler))
    (procedure? (handler-effector handler))
    (= 1 (procedure-arity-min (procedure-arity (cdr handler))))))

(define (add-widget-handler! widget handler)
  (assert (handler? handler))
  (set-widget-handlers!
    widget
    (cons handler (widget-handlers widget))))

(define (clear-widget-handlers! widget)
  (set-widget-handlers! widget '()))

(define set-widget-value! (widget-updater 'value))
(define (widget-value widget)
  (cdr (assq 'value (widget-state widget))))

(define (link widget symbol)
  (assert (symbol? symbol))
  (if (environment-bound? *the-environment* symbol)
    (set-widget-value! widget (environment-lookup *the-environment* symbol))
    (environment-define *the-environment* symbol (widget-value widget)))
  (let ((l (assq symbol widget-links)))
    (if l
      (set-cdr! l (cons widget (cdr l)))
      (set! widget-links (cons (list symbol widget) widget-links))))
  (add-widget-handler!
    widget
    (make-handler
      symbol
      (lambda (state)
        (let ((value (cdr (assq 'value state))))
          (for-each 
            (lambda (w) 
              (if (not (eq? w widget)) 
                (set-widget-value! w value)))
            (cdr (assq symbol widget-links)))
          (environment-assign! *the-environment* symbol value))))))

(define (clear-all-links!)
  (set! widget-links '()))

(define (clear-links! symbol)
  (let ((l (assq symbol widget-links)))
    (if l
      (for-each
        (lambda (w)
          (del-assq! symbol (widget-handlers w)))
        (cdr l)))))