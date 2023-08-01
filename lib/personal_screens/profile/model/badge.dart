import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class UserBadge {
  final String title;
  final String description;
  final String imagePath;

  UserBadge(this.title, this.description, this.imagePath);
}

List<UserBadge> badges = [
  UserBadge('Community Supporter', '0-100 Volunteer Hours', 'assets/icons/community_supporter.png'),
  UserBadge('Community Advocate', '100-999 Volunteer Hours', 'assets/icons/community_advocate.png'),
  UserBadge('Community Ambassador', '1000-4999 Volunteer Hours', 'assets/icons/community_ambassador.png'),
  UserBadge('Community Hero', 'More than or equal 5000 Volunteer Hours', 'assets/icons/community_hero.png'),
];

UserBadge getBadge(int totalVolunteerHours) {
  if (totalVolunteerHours >= 0 && totalVolunteerHours < 100) {
    return badges[0]; // Community Supporter
  } else if (totalVolunteerHours >= 100 && totalVolunteerHours < 1000) {
    return badges[1]; // Community Advocate
  } else if (totalVolunteerHours >= 1000 && totalVolunteerHours < 5000) {
    return badges[2]; // Community Ambassador'
  } else {
    return badges[3]; // Community Hero
  }
}

class BadgeDialog extends StatelessWidget {
  final int totalVolunteerHours;

  BadgeDialog({required this.totalVolunteerHours});

  @override
  Widget build(BuildContext context) {
    final UserBadge badge = getBadge(totalVolunteerHours);
    int hoursNeeded = 0;

    // Calculate hours needed for the next badge
    if (totalVolunteerHours >= 0 && totalVolunteerHours < 100) {
      hoursNeeded = 100 - totalVolunteerHours;
    } else if (totalVolunteerHours >= 100 && totalVolunteerHours < 1000) {
      hoursNeeded = 1000 - totalVolunteerHours;
    } else if (totalVolunteerHours >= 1000 && totalVolunteerHours < 5000) {
      hoursNeeded = 5000 - totalVolunteerHours;
    }

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              badge.imagePath,
              width: 200,
              height: 200,
            ),
            SizedBox(height: 10),
            Text(
              badge.title,
              style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Raleway',
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            ),
            SizedBox(height: 10),
            Text(
              badge.description,
                style: const TextStyle(
                    fontFamily: 'SourceSansPro',
                    color: mainTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)
            ),
            SizedBox(height: 10),
            if (totalVolunteerHours < 5000)
              Text(
                'Hours Needed for Next Badge: $hoursNeeded',
                  style: const TextStyle(
                      fontFamily: 'SourceSansPro',
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)
              ),
            if (totalVolunteerHours >= 5000)
              Text(
                'Congratulations, you are the Community Hero!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'SourceSansPro',
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)
              ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.all(10),
              width: 125,
              height: 50,
              child:ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Close', style: TextStyle(fontFamily: 'Raleway', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class BadgeDialogAll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Community Badges',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Raleway',
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final UserBadge badge = badges[index];
                return ListTile(
                  leading: Image.asset(
                    badge.imagePath,
                    width: 50,
                    height: 50,
                  ),
                  title: Text(
                    badge.title,
                    style: const TextStyle(
                      fontFamily: 'SourceSansPro',
                      color: mainTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  ),
                  subtitle: Text(
                    badge.description,
                    style: const TextStyle(
                        fontFamily: 'SourceSansPro',
                        color: mainTextColor,
                        fontSize: 15)
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.all(10),
              width: 125,
              height: 50,
              child:ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Close', style: TextStyle(fontFamily: 'Raleway', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
