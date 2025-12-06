import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Activity;
import Toybox.Math;
import Toybox.Sensor;



class TestingCadenceView extends WatchUi.View {
    const MAX_BARS = 30;
    const MAX_CADENCE_DISPLAY = 200;
    const BASELINE_AVG_CADENCE = 150;
    const HEIGHT_BASELINE = 170;
    const STEP_RATE = 6;


    private var _writeIndex = 0;
    private var _valueCount = 0;
    //dummy value for cadence range
    private var _idealMinCadence = 80;
    private var _idealMaxCadence = 90;
    
    //display variable
    private var _refreshTimer;
    private var _heartrateDisplay;
    private var _cadenceDisplay;
    private var _cadenceHistory as Array<Float?> = new [MAX_BARS];
    private var _cadenceRangeDisplay;

    enum {
        Beginner = 0.8,
        Intermediate = 1,
        Advanced = 1.02
    }
    //user info (testing with dummy value rn)
    private var _userHeight = 160;
    private var _userSpeed = 0;
    private var _trainingLvl = Beginner;

    function initialize() {
        View.initialize();
        _refreshTimer = new Timer.Timer();
        _refreshTimer.start(method(:refreshScreen), 1000, true);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        _cadenceDisplay = findDrawableById("current_cadence_text");
        _heartrateDisplay = findDrawableById("heartrate_text");
        _cadenceRangeDisplay = findDrawableById("ideal_cadence_text");
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

        //setting ideal cadence range display
        CadenceCalculator();
        if(_idealMinCadence != null && _idealMaxCadence != null){
            var displayString = (_idealMinCadence + " - " + _idealMaxCadence).toString();
            _cadenceRangeDisplay.setText(displayString);
        }
    }

    /*
    Function to retrive speed data from Garmin sensor
    */
    function RetrieveSpeed() as Void
    {
        //(next iteration add speed smoothing)
        try{
            var speed = Sensor.getInfo().speed;
            if(speed == null || speed <= 0){
                System.println("Speed data is null");
                _userSpeed = 0;
                return;
            }
            _userSpeed = speed;

        }
        catch (error){
            System.println("Error retrieving speed data");
            _userSpeed = 0;
            return;
        }
    }

    /*
    Calculate Ideal cadence range based on height, training level, and speed
    Cadence (SPM) = (BASELINE_AVG_CADENCE + STEP_RATE * speed) * sqrt(HEIGHT_BASELINE / height) * trainingLevelFactor
    */
    function CadenceCalculator() as Void
    {
        var cadence_baseline;
        var height_Factor;
        var cadence_final;
        
        if(_userHeight == null){
            _userHeight = 0;
        }
        
        RetrieveSpeed();
        if(_userSpeed != 0){
            cadence_baseline = BASELINE_AVG_CADENCE + STEP_RATE * _userSpeed;

            height_Factor = Math.sqrt(HEIGHT_BASELINE * 1.0 / _userHeight);
            cadence_final = cadence_baseline * height_Factor;

            switch (_trainingLvl) {
                case Beginner:
                        cadence_final = Math.round(cadence_final * Beginner);
                    break;
                case Intermediate:
                        cadence_final= Math.round(cadence_final * Intermediate);
                    break;
                case Advanced:
                        cadence_final= Math.round(cadence_final * Advanced);
                    break;
            }
            _idealMinCadence = (cadence_final - 5).toNumber();
            _idealMaxCadence = (cadence_final + 5).toNumber();
        }
        else{
            System.println("No session started");
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

           if(cadence <= _idealMinCadence)
           {
                dc.setColor(Graphics.COLOR_YELLOW,Graphics.COLOR_BLACK);
           } 
           else if (cadence >= _idealMaxCadence)
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
