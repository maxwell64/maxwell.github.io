Population test;
Obstacle obstacle1;
Obstacle obstacle2;
ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
PVector goal = new PVector(250,10);
int generation = 1;

void setup()
{
  size(500,500);
  test = new Population(500);
  obstacle1 = new Obstacle(0,height/4,width - 100,10);
  obstacle2 = new Obstacle(100,height/2,width - 100,10);
  obstacles.add(obstacle1);
  obstacles.add(obstacle2);

}

void draw()
{
  frameRate(60);
  background(0);
  fill(255,0,0);
  ellipse(goal.x,goal.y,10,10);
  text(generation,20,20);

  if (test.allDead())
  {
    test.calculateFitness();
    test.naturalSelection();
    test.mutantRocks();
    generation ++;

  }
  else
  {
    test.update();
    test.show();
    obstacle1.show();
    obstacle2.show();
  }
}

class Brain
{
  PVector[] directions;
  int step = 0;

  Brain(int size)
  {
    directions = new PVector[size];
    randomize();

  }

  void randomize()
  {
    for (int i =0;i < directions.length;i ++)
    {
      float randomAngle = random(2*PI);
      directions[i] = PVector.fromAngle(randomAngle);

    }
  }

  Brain clone()
  {
    Brain clone = new Brain(directions.length);
    for (int i = 0;i < directions.length;i ++)
    {
      clone.directions[i] = directions[i];

    }

    return clone;
  }

  void mutate()
  {
    float mutationRate = 0.01;

    for (int i = 0;i < directions.length;i ++)
    {
      float rand = random(1);
      if (rand < mutationRate)
      {
        float randomAngle = random(2*PI);
        directions[i] = PVector.fromAngle(randomAngle);
      }

    }
  }
}

class Dot
{
  PVector pos;
  PVector vel;
  PVector acc;
  Brain brain;

  boolean dead = false;
  boolean reachedGoal = false;
  boolean isBest = false;
  float fitness = 0;

  Dot()
  {
    brain = new Brain(1000);
    pos = new PVector(width/2,height-10);
    vel = new PVector(0,0);
    acc = new PVector(0,0);

  }

  void show()
  {
    if (isBest)
    {
      fill(0,255,0);
      ellipse(pos.x,pos.y,8,8);
    }
    else
    {
      fill(255);
      ellipse(pos.x,pos.y,4,4);
    }
  }

  void move()
  {
    if (brain.directions.length > brain.step)
    {
      acc = brain.directions[brain.step];
      brain.step ++;
    }
    else
    {
      dead = true;
    }

    vel.add(acc);
    vel.limit(5);
    pos.add(vel);

  }

  void update()
  {
    if (!dead && !reachedGoal)
    {
      move();
      if (pos.x < 2 || pos.y < 2 || pos.x > width - 2 || pos.y > height - 2)
      {
        dead = true;
      }
      else if (dist(pos.x,pos.y,goal.x,goal.y) < 5)
      {
        reachedGoal = true;
      }
    }
  }

  void calculateFitness()
  {
    if (reachedGoal)
    {
      fitness = 1.0 / 16.0 + 1000.0/(float)(brain.step*brain.step);
    }
    else
    {
      float distanceToGoal = dist(pos.x,pos.y,goal.x,goal.y);
      fitness = 1.0 /(distanceToGoal * distanceToGoal);
    }
  }

  Dot freshRock()
  {
    Dot baby = new Dot();
    baby.brain = brain.clone();
    return baby;

  }
}

class Obstacle
{
  PVector pos;
  int obsW;
  int obsH;

  Obstacle(int x, int y, int w, int h)
  {
    pos = new PVector(x,y);
    obsW = w;
    obsH = h;
  }

  void show()
  {
    fill(0,0,255);
    rect(pos.x,pos.y,obsW,obsH);
  }
}

class Population
{
  Dot[] dots;
  float fitnessSum;
  int gen = 1;
  int bestDot;
  int minStep = 800;

  Population(int size)
  {
    dots = new Dot[size];

    for (int i = 0;i < size;i ++)
    {
      dots[i] = new Dot();

    }
  }

  void show()
  {
    for (int i = 1;i < dots.length;i ++)
    {
      dots[i].show();

    }
    dots[0].show();
  }

  void update()
  {
    for (int i = 0;i < dots.length;i ++)
    {
      if (dots[i].brain.step > minStep)
      {
        dots[i].dead = true;
      }
      for (int j = 0;j < obstacles.size();j ++){
        if (dots[i].pos.x > obstacles.get(j).pos.x && dots[i].pos.x < obstacles.get(j).pos.x + obstacles.get(j).obsW && dots[i].pos.y > obstacles.get(j).pos.y && dots[i].pos.y < obstacles.get(j).pos.y + obstacles.get(j).obsH){
          dots[i].dead = true;
        }
      }
      dots[i].update();

    }
  }

  void calculateFitness()
  {
    for (int i = 0;i < dots.length;i ++)
    {
      dots[i].calculateFitness();

    }
  }

  boolean allDead()
  {
    for (int i = 0;i < dots.length;i ++)
    {
      if (!dots[i].dead && !dots[i].reachedGoal)
      {
        return false;

      }
    }
    return true;
  }

  void naturalSelection()
  {
    Dot[] newDots = new Dot[dots.length];
    setBestDot();

    calculateFitnessSum();

    newDots[0] = dots[bestDot].freshRock();
    newDots[0].isBest = true;
    for (int i = 1;i < newDots.length;i ++)
    {
      //select parent based on fitness
      Dot parent = selectParent();
      //make baby
      newDots[i] = parent.freshRock();

    }
    dots = newDots.clone();
    gen ++;
  }

  void calculateFitnessSum()
  {
    fitnessSum = 0;
    for (int i = 0;i < dots.length;i ++)
    {
      fitnessSum += dots[i].fitness;
    }
    println(fitnessSum);
  }

  Dot selectParent()
  {
    float rand = random(fitnessSum);

    float runningSum = 0;

    for (int i = 0;i < dots.length;i ++)
    {
      runningSum += dots[i].fitness;
      if (runningSum > rand)
      {
        return dots[i];
      }
    }
    return null;
  }

  void mutantRocks()
  {
    for (int i = 1;i < dots.length;i ++)
    {
      dots[i].brain.mutate();

    }
  }

  void setBestDot()
  {
    float max = 0;
    int maxIndex = 0;
    for (int i = 0;i < dots.length;i ++)
    {
      if (dots[i].fitness > max)
      {
        max = dots[i].fitness;
        maxIndex = i;

      }
    }
    bestDot = maxIndex;

    if (dots[bestDot].reachedGoal)
    {
      minStep = dots[bestDot].brain.step;
    }

  }
}
