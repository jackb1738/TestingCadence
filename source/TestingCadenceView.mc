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

    private var _writeIndex = 0;
    private var _valueCount = 0;
    
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

            /**
            Update cadecen using a ring buffer
            **/

            //push cadence to history 
            var newCadence = info.currentCadence.toFloat();
            _cadenceDisplay.setText(info.currentCadence.toString() + "SPM");
            
            _cadenceHistory[_writeIndex] = newCadence;

            //ring buffer
            _writeIndex = (_writeIndex + 1) % MAX_BARS;

            if(_valueCount < MAX_BARS)
            {
                _valueCount ++;
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
        //Always display chart

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

        //check cadence history
        if(_valueCount == 0) {return;}

        //bar scaling
        var barCount = _valueCount;
        if(barCount == 0) {return;}
        var barWidth = chartWidth / MAX_BARS;
        
        //get the index of the oldest value
        var startIndex = (_writeIndex - barCount + MAX_BARS) % MAX_BARS;
        //draw each bar
        for(var i = 0; i < barCount; i++)
        {
            var index = (startIndex + i) % MAX_BARS;
            var cadence = _cadenceHistory[index];
            if(cadence == null)
            {
                cadence = 0.0;
            }

           if(cadence < IDEAL_MIN_CADENCE)
           {
                dc.setColor(Graphics.COLOR_YELLOW,Graphics.COLOR_BLACK);
           } 
           else if (cadence > IDEAL_MAX_CADENCE)
           {
                dc.setColor(Graphics.COLOR_RED,Graphics.COLOR_BLACK);
           }
           else
           {
                dc.setColor(Graphics.COLOR_GREEN,Graphics.COLOR_BLACK);
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
