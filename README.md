# Math App

A fun and engaging Flutter application to help practice and improve math skills.

## Features

- **Times tables:** Explore tables from 1 to 12 with dot groups and repeated addition, then practice a single table.
- **Practice:** Try multiplication, addition, or subtraction with immediate feedback. Missed facts come back after a few questions.
- **Quiz:** Answer 10 questions at your own pace or take a timed challenge. Practice missed facts directly from the results.
- **Progress:** Track each child's answers on their own profile and revisit facts they missed or used a hint on.
- **Settings:** Choose tables for mixed rounds, adjust the addition and subtraction number limit, and switch between multiple choice and a number pad. Game sounds can be turned off per profile.

## Folder Structure

The `lib` folder is organized as follows:

*   `main.dart`: The entry point of the application.
*   `screens/`: Contains the UI for different screens of the app (e.g., `learn_screen.dart`, `practice_screen.dart`).
*   `models/`: Contains the data models for the application (e.g., `profile_model.dart`, `settings_model.dart`).
*   `managers/`: Contains the business logic for the application (e.g., `profile_manager.dart`, `question_manager.dart`).

## How to Run

1.  Clone this repository.
2.  Install Flutter 3.50.1 or a newer stable release.
3.  Run `flutter pub get` to install the dependencies.
4.  Run `flutter run` to start the application.
