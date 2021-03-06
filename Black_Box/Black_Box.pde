Box box;
Tendrils tendrils;
ArrayList<ParticleSystem> particleSystems;
MusicPlayer song1;
MusicPlayer song2;
MusicPlayer screamControls;
MusicPlayer introSound;

boolean DEBUG_SKIP_INTRO = false;
boolean DEBUG_MUTE_SOUND = false;

boolean isMouseDown;
boolean introDone = false;

static int[] maxTendrilLengths;
static int maxTendrilLength;

static float cameraShakeOverride = 0.0;
static float cameraShakeDecayFactor = 1.0;

static float targetTextBrightness = 2;
static float textBrightness = 2;
static float textFadeEase = 0.02;

static int ticksWaited = 0; 
static int textFadeWait = 60;

static int outroWaitTime = 10000;
static int timeOfDeath;

static int MAX_NUM_BREAKS = 7;
static int DEFAULT_MAX_TENDRIL_LENGTH;

static Point boxCenter;

static float[] maxScreenShake;
static float[] defaultPlaybackRates;

static PFont mainTitleFont;

int finalTendrilsLeftCount;

// for splitting particle systems during retraction
float twoFifthPI = 2*(float)(Math.PI)/5f;

void setupAudio(){
  song1 = new MusicPlayer("coltrane.aif");
  song1.pause();
  
  song2 = new MusicPlayer("coltrane.aif");
  song2.pause();
  song2.shouldAdjustRate = false;
  
  screamControls = new MusicPlayer("scream.aif");
//  screamControls.shouldAdjustRate = false;
  screamControls.pause();
  screamControls.setShouldLoop(true);

  introSound = new MusicPlayer("intro2.aif");
  introSound.pause();
  introSound.shouldAdjustRate = false;
  introSound.setShouldLoop(true);
  introSound.setTargetVolume(0, 1);
  introSound.updateVolume();
}

public int sketchWidth() {
  return displayWidth;
}

public int sketchHeight() {
  return displayHeight;
}

boolean sketchFullScreen() {
  return true;
}

void initMaxScreenShake(){
  int numItems = MAX_NUM_BREAKS + 2;
  
  maxScreenShake = new float[numItems];
  
  for (int i = 0; i < numItems; ++i){
    maxScreenShake[i] = min(abs(5 - abs(i - 0.75 * numItems)) * (9.0 / 6.0), 7.5)/7.5 + 0.1;
  }
}

void initDefaultPlaybackRates(){
  int numItems = MAX_NUM_BREAKS + 2;
  
  defaultPlaybackRates = new float[numItems];
  
  for (int i = 0; i < numItems; ++i){
    defaultPlaybackRates[i] = (abs(5 - abs(i - 0.75 * numItems)) * (2.0/11.0));
    
    if (defaultPlaybackRates[i] > 0.9){
      defaultPlaybackRates[i] += 0.3;
    }
    else if (defaultPlaybackRates[i] < 0.5){
      defaultPlaybackRates[i] = 1.0 - defaultPlaybackRates[i];
    }
  }
}

void setupMaxTendrilLengths(){
  int len = MAX_NUM_BREAKS + 1;

  DEFAULT_MAX_TENDRIL_LENGTH = (int)floor(0.375 * sketchHeight());
  int baseLength = DEFAULT_MAX_TENDRIL_LENGTH;

  maxTendrilLengths = new int[len];

  if (MAX_NUM_BREAKS > 6){
    maxTendrilLengths[0] = 0;
    maxTendrilLengths[1] = ceil(baseLength * 1.16);
    maxTendrilLengths[2] = ceil(baseLength * 1.82);
    maxTendrilLengths[3] = ceil(baseLength * 0.87);
    maxTendrilLengths[4] = ceil(baseLength * 1.1);
    maxTendrilLengths[5] = ceil(baseLength * 0.6);
    maxTendrilLengths[6] = ceil(baseLength * 1.3);

    for (int i = 7; i < len; ++i){
      maxTendrilLengths[i] = baseLength;
    }
  }
}

void updateTendrilLength(){
  float easeFactor = 0.1;

  // float factor = (float)box.numBreaks/(MAX_NUM_BREAKS-2);

  if (box.numBreaks >= 5){
    maxTendrilLength = ceil(maxTendrilLength * (1.0 + (box.numBreaks/2040.0)));
  } else if (box.numBreaks == 4){
    maxTendrilLength = floor(maxTendrilLength * (0.99999 - (box.numBreaks/640.0)));
  } else if (box.numBreaks == 1) {
    // do nothing
  } else {
    maxTendrilLength = ceil(maxTendrilLength * (0.99999 - (box.numBreaks/140.0)));
  }

  maxTendrilLength = max(maxTendrilLength, 60);
}

// The statements in the setup() function 
// execute once when the program begins
void setup() {
  randomSeed(1);
  
  mainTitleFont = createFont("Avenir", 10);
  
  textAlign(CENTER, CENTER);
  
  setupMaxTendrilLengths();
  
  initMaxScreenShake();
  initDefaultPlaybackRates();
  
//  size(SCREEN_WIDTH, SCREEN_HEIGHT);  // Size must be the first statement
  stroke(255);     // Set line drawing color to white
  frameRate(30);
  background(0,0,0);
  
  boxCenter = new Point(sketchWidth()/2.0, sketchHeight()/2.0);
  
  box = new Box(this, boxCenter.x, boxCenter.y, 0.0625 * sketchHeight());
  tendrils = new Tendrils(10, 
                          2f, 7f, 0.1f, 2f,
                          1000f, 10000f, 0.97f, 1f);
                          
  setupAudio();

  particleSystems = new ArrayList<ParticleSystem>();
  finalTendrilsLeftCount = 10;

  targetTextBrightness = 280;
  
  if (DEBUG_SKIP_INTRO){
    box.disabled = false;
    box.fillColor = color(255);
    introDone = true;
  } else {
    if (!DEBUG_MUTE_SOUND){
      introSound.play();
      introSound.setTargetVolume(0.4, 0.07);
    }
  }
}

void shakeCamera(float amount){  
  if (cameraShakeOverride < 0.1) cameraShakeOverride = 0;
  
  amount = max(amount, cameraShakeOverride);
  
  float x = random(-9 * amount, 9 * amount);
  float y = random(-9 * amount, 9 * amount);
  
  translate(x, y);
  
  cameraShakeOverride = cameraShakeOverride * (1 - cameraShakeDecayFactor);
}

void setCameraShake(float amount, float decayFactor){
  cameraShakeOverride = amount;
  cameraShakeDecayFactor = decayFactor;
}

void startInteraction(){
  box.disabled = false;
}

float outroProgress(){
  if (!box.isDead) return 0.0;
  
  return max(0, min((float)textBrightness / 255.0, 1));
}

void drawOutro(){
  if (millis() - timeOfDeath > outroWaitTime){
    
    textBrightness = ceil((textBrightness * (1 - textFadeEase)) + (targetTextBrightness * textFadeEase));
  
    textBrightness = min(255, max(0, textBrightness));
  
    fill(255, 255, 255, textBrightness);
    textFont(mainTitleFont);
    
    float x = sketchWidth()/2.0;
    float h = sketchHeight();
    
    textSize(0.0875 * h);
    text("black box", x, h/6.2);
    
    float textHeight = 0.0875 * h * 0.28;
    
    textSize(textHeight);
    textLeading(textHeight * 1.4);
    text("- animation -\nandrew sweet\ndave yan\n\n- music -\nthe father and the son and the holy ghost\nby john coltrane\n\n\ncreated for experimental animation\nat carnegie mellon, 2015",
          x, (8.0 * h)/15.0);
  }
}

void drawIntro(){
  if (textBrightness > 3){
    fill(textBrightness);
    textFont(mainTitleFont);
    
    textSize(0.0875 * sketchHeight());
    text("black box", sketchWidth()/2.0, sketchHeight()/2.05);
  }
  
  textBrightness = ceil((textBrightness * (1 - textFadeEase)) + (targetTextBrightness * textFadeEase));

  textBrightness = min(255, max(0, textBrightness));

  if (textBrightness > 250){
    if (ticksWaited > textFadeWait){
      targetTextBrightness = -52;
    } else {
      ticksWaited++;
    }
  } else if (textBrightness < 3) {
    textBrightness = 0;
    float targetFill = 300;
    
    float fill = ceil(((float)brightness(box.fillColor) * (1 - textFadeEase)) + (targetFill * textFadeEase));
    fill = min(255, max(0, fill));
    box.fillColor = color(fill);
    
    if (box.disabled && fill > 110){
      introSound.setTargetVolume(-0.3, textFadeEase/2.0);
      startInteraction();
    }
    
    if (fill > 252){
      box.fillColor = color(255);
      introDone = true;
    }
  }
}

// The statements in draw() are executed until the 
// program is stopped. Each statement is executed in 
// sequence and after the last line is read, the first 
// line is executed again.
void draw() {
  background(box.numBreaks * (40.0 / (MAX_NUM_BREAKS+1)), 0, 0); 

  pushMatrix();
  
  // shake the camera
  if (!box.isDead){
    float shakeAmount = tendrils.currentLengthSquared()/(maxTendrilLength * maxTendrilLength);
    shakeAmount *= shakeAmount;
    
    shakeAmount *= maxScreenShake[box.numBreaks];
    
    shakeCamera(shakeAmount);
  }
  
  // update the particle system
  updateParticlesPosition();
  noStroke();
  rectMode(CENTER);
  colorMode(HSB, 100);
  for(int i = 0; i < particleSystems.size(); i++)
      particleSystems.get(i).draw();
  colorMode(RGB, 255);
  rectMode(CORNER);

  if (box.broken){    
    if(finalTendrilsLeftCount == 2 && 
       0f < box.velocity() && box.velocity() < 2f)
    {
      tendrils.deleteTendrils(1);
      finalTendrilsLeftCount--;
    }
    if(finalTendrilsLeftCount == 1 &&
       0f < box.velocity() && box.velocity() < 0.1f)
    {
      tendrils.deleteTendrils(1); 
      finalTendrilsLeftCount--;
      
      screamControls.setTargetVolume(-0.4, 0.6);
    }
    box.update();
    tendrils.draw();
  }
  
  
  box.draw();
  song1.update();
  song2.update();
  
  updateTendrilLength();

  screamControls.update();
  
  song2.setTargetPlaybackRate(defaultPlaybackRates[box.numBreaks], 0.3);
  popMatrix();
  
  if (!introDone){
    introSound.updateVolume();
//    println();
    drawIntro();
  }
  
  if (box.isDead){
    drawOutro();
  }
}

void onBreakBox(){
  if (!DEBUG_MUTE_SOUND){
    song1.play();
    song2.play();
  }
  
  float denominator = 7.0 + box.numBreaks;
  
  if (box.numBreaks == 5 && !DEBUG_MUTE_SOUND) {
    denominator *= 7.8;
    screamControls.play();
  }
  
  if (box.numBreaks > 5 && !DEBUG_MUTE_SOUND){
    screamControls.play();
  }

  maxTendrilLength = maxTendrilLengths[box.numBreaks];
  
  setCameraShake(1.0, 1.0/denominator);
}

void onReconnectBox(){
  song1.pause();
  song2.pause();
  screamControls.pause();
}

void onDeath(){
  song1.kill();
  song2.pause();
  
  if (!DEBUG_MUTE_SOUND){
    screamControls.play();
  }
  
  timeOfDeath = millis();
  
  textBrightness = 0.0;
  targetTextBrightness = 258;
}

void mousePressed(){
  if (!box.isDead){
    box.mousePressed(); 
  }
  isMouseDown = true;
}

void mouseDragged(){
  if (!box.isDead){
    box.mouseDragged();
  }
}

void mouseReleased(){
  if (!box.isDead){
    box.mouseReleased();
  }
  isMouseDown = false;
}

void moveTendrils(Point p)
{
  tendrils.setEndPoint(p);
}



void updateParticlesPosition()
{
  if(particleSystems.size() > 1)
  {
    ParticleSystem p1 = particleSystems.get(particleSystems.size()-1);
    ParticleSystem p2 = particleSystems.get(particleSystems.size()-2);
    Point bp = box.pieceCoords();

    // start splitting at 10% (0.1f) time left
    float len = DEFAULT_MAX_TENDRIL_LENGTH - 80;

    float sqD = len * len;
    float angle = twoFifthPI * (1.1f - Math.min((tendrils.currentLengthSquared()/sqD)/0.1f, 1f));

    // apply rotation matrix
    Point v = new Point(bp.x-boxCenter.x, bp.y-boxCenter.y);
    Point m1 = new Point(boxCenter.x + cos(angle)*v.x - sin(angle)*v.y, 
                         boxCenter.y + sin(angle)*v.x + cos(angle)*v.y);
    Point m2 = new Point(boxCenter.x + cos(-angle)*v.x - sin(-angle)*v.y, 
                         boxCenter.y + sin(-angle)*v.x + cos(-angle)*v.y);

    if(p1.isAlive())
    {
      p1.setTarget(m1.x, m1.y);
    }
    if(p2.isAlive())
    {
      p2.setTarget(m2.x, m2.y);
    }

    // stop particle emission once box is no longer broken
    if(!box.broken)
    {
      p1.setLeftToGenCount(0);
      p2.setLeftToGenCount(0);
    }
  }
}

// super hax fast sqrt function
// source: http://forum.processing.org/one/topic/super-fast-square-root.html
public float fastSqrt(float x) {
  int i = Float.floatToRawIntBits(x);
  i = 532676608 + (i >> 1);
  return Float.intBitsToFloat(i);
}


// increase the pulled count
public void increasePullCount() {
  updateTendrilState();
  updateParticlesState();
}
