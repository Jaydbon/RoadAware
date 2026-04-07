import 'package:flutter/material.dart';
import '../db/repositories.dart';

class DrivingStatsScreen extends StatefulWidget {
  static const routeName = '/stats';

  final VoidCallback onOpenUserPanel;

  const DrivingStatsScreen({
    super.key,
    required this.onOpenUserPanel,
  });

  @override
  State<DrivingStatsScreen> createState() => _DrivingStatsScreenState();
}

class _DrivingStatsScreenState extends State<DrivingStatsScreen> {
  final TripRepo tripRepo = TripRepo();
  final EventRepo eventRepo = EventRepo();

  TripSummary? latest;
  bool loading = true;

  // Gamification stats
  int currentScore = 100;
  int smoothBrakingStreak = 0;
  bool hasFeatherFoot = false;
  bool hasZenMaster = false;
  
  // NEW Badges
  bool hasFlawless = false;
  bool hasRoadWarrior = false;
  bool hasGuardian = false;

  // Breakdown scores for the UI bars
  int brakeScore = 100;
  int accelScore = 100;

  @override
  void initState() {
    super.initState();
    _loadDataAndBadges();
  }

  Future<void> _loadDataAndBadges() async {
    // Fetch up to 10 recent trips to calculate badges
    final trips = await tripRepo.latestTrips(limit: 10);
    
    if (trips.isEmpty) {
      if (mounted) setState(() => loading = false);
      return;
    }

    final latestTrip = trips.first;
    int tempStreak = 0;
    bool streakBroken = false;
    
    int tripsWithoutAccel = 0;
    bool zenMasterActive = trips.length >= 3; 

    for (var i = 0; i < trips.length; i++) {
      final trip = trips[i];
      final counts = await eventRepo.eventCounts(trip.id);
      final brakes = counts['brake'] ?? 0;
      final accels = counts['accel'] ?? 0;

      // Calculate breakdown specifically for the latest trip (index 0)
      if (i == 0) {
        brakeScore = (100 - (brakes * 5)).clamp(0, 100);
        accelScore = (100 - (accels * 3)).clamp(0, 100);
      }

      // 1. Smooth Braking Streak
      if (brakes == 0 && !streakBroken) {
        tempStreak++;
      } else {
        streakBroken = true;
      }

      // 2. Feather Foot (3 total recent trips with 0 hard accelerations)
      if (accels == 0) {
        tripsWithoutAccel++;
      }

      // 3. Zen Master (Last 3 trips all scored above 90)
      if (i < 3) {
        if (trip.score == null || trip.score! < 90) {
          zenMasterActive = false;
        }
      }
    }

    if (mounted) {
      setState(() {
        latest = latestTrip;
        currentScore = latestTrip.score ?? 100;
        
        // Original Badges
        smoothBrakingStreak = tempStreak;
        hasFeatherFoot = tripsWithoutAccel >= 3;
        hasZenMaster = zenMasterActive && trips.length >= 3;
        
        // New Badges Logic
        hasFlawless = currentScore == 100;
        hasRoadWarrior = trips.length >= 10;
        hasGuardian = trips.length >= 5 && trips.take(5).every((t) => t.score == 100);
        
        loading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDataAndBadges, 
      color: Colors.cyan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Overall Score Display ---
              Text(
                latest == null ? 'No Trips Yet' : 'Latest Trip Score',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Container(
                width: 180,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getScoreColor(currentScore),
                  boxShadow: [
                    BoxShadow(
                      color: _getScoreColor(currentScore).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Text(
                  '$currentScore',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // --- Trip Breakdown Section ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trip Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _StatBar(
                title: 'Smooth Braking',
                score: brakeScore,
                activeColor: Colors.orange,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 16),
              _StatBar(
                title: 'Smooth Acceleration',
                score: accelScore,
                activeColor: Colors.cyan,
                icon: Icons.speed_rounded,
              ),

              const SizedBox(height: 40),
              
              // --- Badges & Achievements Section (Scrollable) ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Badges',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none, 
                  children: [
                    _BadgeCard(
                      icon: '🔥',
                      title: 'Smooth Operator',
                      description: '$smoothBrakingStreak trip streak without hard braking.',
                      isUnlocked: smoothBrakingStreak > 0,
                      activeColor: Colors.deepOrange,
                    ),
                    const SizedBox(width: 16),
                    _BadgeCard(
                      icon: '💯',
                      title: 'Flawless',
                      description: 'Score a perfect 100 on your latest trip.',
                      isUnlocked: hasFlawless,
                      activeColor: Colors.amber,
                    ),
                    const SizedBox(width: 16),
                    _BadgeCard(
                      icon: '🪶',
                      title: 'Feather Foot',
                      description: 'Complete 3 recent trips with zero hard accels.',
                      isUnlocked: hasFeatherFoot,
                      activeColor: Colors.lightBlue,
                    ),
                    const SizedBox(width: 16),
                    _BadgeCard(
                      icon: '🧘',
                      title: 'Zen Master',
                      description: 'Score 90+ on your last 3 consecutive trips.',
                      isUnlocked: hasZenMaster,
                      activeColor: Colors.purple,
                    ),
                    const SizedBox(width: 16),
                    _BadgeCard(
                      icon: '🛡️',
                      title: 'Guardian',
                      description: 'Score a perfect 100 on 5 consecutive trips.',
                      isUnlocked: hasGuardian,
                      activeColor: Colors.teal,
                    ),
                    const SizedBox(width: 16),
                    _BadgeCard(
                      icon: '🏆',
                      title: 'Road Warrior',
                      description: 'Log 10 total trips in the app.',
                      isUnlocked: hasRoadWarrior,
                      activeColor: Colors.indigo,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- The animated progress bar for sub-scores ---
class _StatBar extends StatelessWidget {
  final String title;
  final int score;
  final Color activeColor;
  final IconData icon;

  const _StatBar({
    required this.title,
    required this.score,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: activeColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                  ),
                  Text(
                    '$score / 100', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score / 100.0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- HORIZONTAL BADGE CARD WIDGET ---
class _BadgeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final Color activeColor;

  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget emojiIcon = Text(
      icon,
      style: const TextStyle(fontSize: 42),
    );

    if (!isUnlocked) {
      emojiIcon = Opacity(
        opacity: 0.3, 
        child: emojiIcon,
      );
    }

    return Container(
      width: 140, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? activeColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        border: Border.all(
          color: isUnlocked ? activeColor.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                child: emojiIcon,
              ),
              if (isUnlocked)
                Icon(Icons.check_circle, color: activeColor, size: 18)
              else
                const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? activeColor : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isUnlocked ? Colors.black87 : Colors.grey,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}