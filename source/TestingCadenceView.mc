import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.Timer;

class TestingCadenceView extends WatchUi.View {
    const MAX_BARS = 30;
    //dummy ideal cadence values
    const IDEAL_MIN_CADENCE = 88;
    const IDEAL_MAX_CADENCE = 95;
    const MAX_CADENCE_DISPLAY = 150;

    private var _counter = 0;
    
    private var _cadenceHistory as Array<Float?> = new [MAX_BARS];
    private var _cadenceDisplay;
    private var _refreshTimer;
    private var _heartrateDisplay;

    

    function initialize() {
        View.initialize();
        _refreshTimer = new Timer.Timer();
        _refreshTimer.start(method(:refreshScreen), 1000, true);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        _cadenceDisplay = findDrawableById("cadence_text");
        _heartrateDisplay = findDrawableById("heartrate_text");
    }

    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        //update the display for current cadence
        displayActivity();
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        //display chart
        drawCadenceChart(dc);
    }

    function onHide() as Void {
    }

    function refreshScreen() as Void{
        WatchUi.requestUpdate();
    }

    function displayActivity() as Void{
        var info = Activity.getActivityInfo();

        //Setting real-time cadence display & storing values for drawing graph
        if (info != null && info.currentCadence != null){
            
            //Display the current cadence
            _cadenceDisplay.setText(info.currentCadence.toString() + "SPM");

            /**
            Pushing new value to array. (Next iteration uses buffer for better control
            and less expensive operations)
            **/
            //push cadence to history 
            var newCadence = info.currentCadence.toFloat();
            //add the initial 30 values to array
            if(_counter < MAX_BARS)
            {
                _cadenceHistory[_counter] = newCadence;
                _counter++;
            }else//*in progress* (keeps pushing new values?)
            {
                _cadenceHistory = _cadenceHistory.slice(1, null);
                _cadenceHistory.add(newCadence);
            }
        }else{
            _cadenceDisplay.setText("--");
        }

        //Setting real-time heartrate display
        if (info != null && info.currentHeartRate != null){
            _heartrateDisplay.setText(info.currentHeartRate.toString() + "BPM");
        }else{
            _heartrateDisplay.setText("--");
        }
    }
    
    /**
    Function to continous update the chart with live cadence data. 
    The chart is split into bars each representing a candence reading,
    Each bar data is retrieve from an CadenceHistory array which is updated every tick
    Each update the watchUI redraws the chart with the latest data.
    }
    **/
    function drawCadenceChart(dc as Dc) as Void
    {
        //check cadence history
        if(_cadenceHistory.size() == 0) {return;}

        var width = dc.getWidth();
        var height = dc.getHeight();

        //margins value
        var margin = 10 * width / 100;
        var marginLeftRightMultiplier = 1.2;
        var marginTopMultiplier = 0.5;
        var marginBottomMultiplier = 2;

        //chart position
        
        var chartLeft = margin*marginLeftRightMultiplier;
        var chartRight = width - chartLeft;
        var chartTop = height * 0.5 + margin * marginTopMultiplier;
        var chartBottom = height - margin*marginBottomMultiplier;
        var chartWidth = chartRight - chartLeft;
        var chartHeight = chartBottom - chartTop;

        //background
        dc.drawRectangle(chartLeft, chartTop, chartWidth, chartHeight);

        //bar scaling
        var barCount = _cadenceHistory.size();
        if(barCount <= 0) {return;}
        var barWidth = chartWidth / barCount;

        //draw the bars
        for(var i = 0; i < barCount; i++)
        {
            var cadence = _cadenceHistory[i];

            if (cadence == null){
                continue;
            }

            //set bar color based on ideal cadence range
            if (cadence >= IDEAL_MIN_CADENCE && cadence <= IDEAL_MAX_CADENCE) 
            {
                dc.setColor(Graphics.COLOR_GREEN,Graphics.COLOR_BLACK);
            } 
            else if (cadence < IDEAL_MIN_CADENCE)
            {
                dc.setColor(Graphics.COLOR_YELLOW,Graphics.COLOR_BLACK);
            }
            else if (cadence > IDEAL_MAX_CADENCE)
            {
                dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_BLACK);
            }

            //calculate bar height and position
            var barHeight = (cadence / MAX_CADENCE_DISPLAY) * chartHeight;
            var x = chartLeft + i * barWidth;
            var y = chartBottom - barHeight;

            //seperation between each bar
            var barOffset = 1;

            dc.fillRectangle(x, y, barWidth-barOffset, barHeight);
        }

        
    }

}
