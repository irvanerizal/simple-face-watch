import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Minimal Lines application entry point
class MinimalLinesApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of the application
    function getInitialView() {
        return [new MinimalLinesView()];
    }
}
