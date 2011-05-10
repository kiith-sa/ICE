//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///AI and human player classes.
module pong.player;
@safe


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
        @property void score(BallBody ball_body){score_++;}

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

        ///Destroy this player
        void die(){}

    protected:
        /**
         * Construct a player.
         * 
         * Params:  name   = Player name.
         *          paddle = Paddle controlled by the player.
         */
        this(in string name, Paddle paddle)
        {
            name_ = name;
            paddle_ = paddle;
        }
}

///AI player.
final class AIPlayer : Player
{
    protected:
        ///Timer determining when to update the AI.
        Timer update_timer_;
        ///Position of the ball during last AI update.
        Vector2f ball_last_;

    public:
        /**
         * Construct an AI player.
         * 
         * Params:  name          = Player name.
         *          paddle        = Paddle controlled by the player.
         *          update_period = Time period of AI updates.
         */
        this(in string name, Paddle paddle, in real update_period)
        {
            super(name, paddle);
            update_timer_ = Timer(update_period);
        }

        override void update(Game game)
        {
            if(update_timer_.expired())
            {
                update_timer_.reset();

                //currently only support zero or one ball
                const Ball[] balls = game.balls;
                assert(balls.length <= 1, "AI supports only zero or one ball at the moment");

                if(balls.length == 0)
                {
                    //Setting last ball position to center of paddle limits prevents
                    //any weird AI movements when ball first appears.
                    ball_last_ = paddle_.limits.center;
                    move_to_center();
                    return;
                }
                const Ball ball = balls[0];

                const float distance = paddle_.limits.distance(ball.position);
                const float distance_last = paddle_.limits.distance(ball_last_);
                
                //If the ball is closing to paddle movement area
                if(distance_last >= distance){ball_closing(ball);}       
                //If the ball is moving away from paddle movement area
                else{move_to_center();}

                ball_last_ = ball.position;
            }
        }

    protected:
        ///React to the ball closing in.
        void ball_closing(in Ball ball)
        {
            //If paddle x position is roughly equal to ball, no need to move
            if(equals(paddle_.position.x, ball.position.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < ball.position.x){paddle_.move_right();}
            else{paddle_.move_left();}
        }

        ///Move the paddle to center.
        void move_to_center()
        {
            Vector2f center = paddle_.limits.center;
            //If paddle x position is roughly in the center, no need to move
            if(equals(paddle_.position.x, center.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < center.x){paddle_.move_right();}
            else{paddle_.move_left();}
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
            platform_.key.connect(&key_handler);
        }
        
        ///Destroy this HumanPlayer.
        override void die(){platform_.key.disconnect(&key_handler);}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                if(key == Key.Right)
                {
                    paddle_.move_right();
                    return;
                }
                if(key == Key.Left)
                {
                    paddle_.move_left();
                    return;
                }
            }
            else if(state == KeyState.Released)
            {
                if(key == Key.Right)
                {
                    if(platform_.is_key_pressed(Key.Left))
                    {
                        paddle_.move_left();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
                else if(key == Key.Left)
                {
                    if(platform_.is_key_pressed(Key.Right))
                    {
                        paddle_.move_right();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
            }
        }
}
