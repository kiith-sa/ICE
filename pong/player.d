//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///AI and human player classes.
module pong.player;


import pong.paddle;
import pong.ball;
import pong.game;
import platform.platform;
import time.timer;
import math.math;
import math.vector2;


///Player controlling a paddle.
abstract class Player
{
    protected:
        ///Player name.
        const string name_;
        ///Current player score.
        uint score_ = 0;

        ///Paddle controlled by this player.
        Paddle paddle_;

    public:
        ///Increase score of this player.
        @property void score(const BallBody ballBody){score_++;}

        ///Get score of this player.
        @property int score() const {return score_;}

        ///Get name of this player.
        @property string name() const {return name_;}

        /**
         * Update player state.
         * 
         * Params:  game = Reference to the game.
         */
        void update(Game game){}

    protected:
        /**
         * Construct a player.
         * 
         * Params:  name   = Player name.
         *          paddle = Paddle controlled by the player.
         */
        this(in string name, Paddle paddle)
        {
            name_   = name;
            paddle_ = paddle;
        }
}

///AI player.
final class AIPlayer : Player
{
    protected:
        ///Timer determining when to update the AI.
        Timer updateTimer_;
        ///Position of the ball during last AI update.
        Vector2f ballLast_;

    public:
        /**
         * Construct an AI player.
         * 
         * Params:  name          = Player name.
         *          paddle        = Paddle controlled by the player.
         *          updatePeriod = Time period of AI updates.
         */
        this(in string name, Paddle paddle, in real updatePeriod)
        {
            super(name, paddle);
            updateTimer_ = Timer(updatePeriod);
        }

        override void update(Game game)
        {
            if(updateTimer_.expired())
            {
                updateTimer_.reset();

                //currently only support zero or one ball
                const Ball[] balls = game.balls;
                assert(balls.length <= 1, "AI supports only zero or one ball at the moment");

                if(balls.length == 0)
                {
                    //Setting last ball position to center of paddle limits prevents
                    //any weird AI movements when ball first appears.
                    ballLast_ = paddle_.limits.center;
                    moveToCenter();
                    return;
                }

                const Ball ball = balls[0];
                const float distance = paddle_.limits.distance(ball.position);
                const float distanceLast = paddle_.limits.distance(ballLast_);
                
                //If the ball is closing to paddle movement area
                if(distanceLast >= distance){ballClosing(ball);}       
                //If the ball is moving away from paddle movement area
                else{moveToCenter();}

                ballLast_ = ball.position;
            }
        }

    protected:
        ///React to the ball closing in.
        void ballClosing(in Ball ball)
        {
            //If paddle x position is roughly equal to ball, no need to move
            if(equals(paddle_.position.x, ball.position.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < ball.position.x){paddle_.moveRight();}
            else{paddle_.moveLeft();}
        }

        ///Move the paddle to center.
        void moveToCenter()
        {
            Vector2f center = paddle_.limits.center;
            //If paddle x position is roughly in the center, no need to move
            if(equals(paddle_.position.x, center.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < center.x){paddle_.moveRight();}
            else{paddle_.moveLeft();}
        }
}

///Human player controlling the game through user input.
final class HumanPlayer : Player
{
    private:
        ///Platform for user input.
        Platform platform_;

    public:
        /**
         * Construct a human player controlling specified paddle.
         *
         * Params:  platform = Platform for user input.
         *          name     = Name of the player.
         *          paddle   = Paddle controlled by the player.
         */
        this(Platform platform, in string name, Paddle paddle)
        {
            super(name, paddle);
            platform_ = platform;
            platform_.key.connect(&keyHandler);
        }
        
        ///Destroy this HumanPlayer.
        ~this(){platform_.key.disconnect(&keyHandler);}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void keyHandler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                if(key == Key.Right)
                {
                    paddle_.moveRight();
                    return;
                }
                if(key == Key.Left)
                {
                    paddle_.moveLeft();
                    return;
                }
            }
            else if(state == KeyState.Released)
            {
                if(key == Key.Right)
                {
                    if(platform_.isKeyPressed(Key.Left))
                    {
                        paddle_.moveLeft();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
                else if(key == Key.Left)
                {
                    if(platform_.isKeyPressed(Key.Right))
                    {
                        paddle_.moveRight();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
            }
        }
}
