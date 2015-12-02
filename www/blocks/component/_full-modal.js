var FullModalComponent = function(ele, context){

    var $ele = $(context ? context : 'body').find(ele),
        __self__ = this;

    __self__.hide = function(){
        $ele.removeClass('open');
        $('body').scrollTop(0);
    };

    __self__.show = function(){
        $ele.focus();
        $ele.addClass('open');
    };

    __self__.toggleOn = function(event, ele, context){
        $(context ? context : 'body').find(ele).on(event, function(){
            __self__.toggle();
        });
    };

};
