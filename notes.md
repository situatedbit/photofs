# Steps I started, but didn't finish for rails engine migration
- Create engine class and create an isolated engine namespace: PhotoFS
- move activerecord models to app/models and do a require_relative from lib for compatibility with gem users
- add versions to migrations [4.2] for the old stuff
- pulled out standalone migrations which were replaced with active support migrations
- 
