var SlideOutComponent = function(ele, context, activationEvent){

    var $ele = $(context ? context : 'body').find(ele),
        $overlay = $('body').children('.slide-out-overlay'),
        id = $ele.attr('id'),
        triggerEvent = activationEvent,
        __self__ = this;

    $ele.addClass('slide-out');

    if($overlay.length < 1){
        $overlay = $('<div class="slide-out-overlay"></div>').appendTo($('body'));
    }

    $overlay.on(triggerEvent,function(e){ __self__.toggle(); e.stopPropagation; return false; });

    __self__.toggle = function(){
        var active = $ele.attr('data-state') == 'active' ? false : 'active';
        $ele.attr('data-state', active);
        // add body 'slideout-state' so body can be modified when slideout is active.
        $('body').attr('slideout-state', active);

        if (active === false) {
            // Re-enable scrolling in mobile views.
            $('body').off('touchmove.slideout');
        } else {
            // Disable scrolling in mobile views.
            $('body').on('touchmove.slideout', function(e) {
                e.preventDefault();
            });
        }
    };

    __self__.open = function(){
        $ele.attr('data-state', 'active');
        $('body').attr('slideout-state', 'active');

        $('body').on('touchmove.slideout', function(e) {
            e.preventDefault();
        });
    };

    __self__.close = function(){
        $ele.attr('data-state', false);
        $('body').attr('slideout-state', false);
        $('body').off('touchmove.slideout');
    };

    __self__.toggleOn = function(ele, context){
        $(context ? context : 'body').find(ele).on(triggerEvent, function(e){
            __self__.toggle();
            e.stopPropagation;
            return false;
        });
    };
};
