/// Astra AI Core Module
///
/// This is the main entry point for the Astra AI integration in the Doctor App.
/// It provides all the core infrastructure needed for Astra Brain integration.
library;

/// Utils - Configuration, logging, and exceptions
export 'utils/utils.dart';

/// Models - Data models for conversations and actions
export 'models/models.dart';

/// Services - Service layer for API communication
export 'services/services.dart';

/// Repositories - Repository layer for caching and offline support
export 'repositories/repositories.dart';

/// Controllers - Provider-based state management
export 'controllers/controllers.dart';

/// Providers - Provider wrappers for easy integration
export 'providers/astra_provider.dart';

/// Actions - Action definitions and dispatcher
export 'actions/actions.dart';
export 'actions/action_dispatcher.dart';

/// Navigation - App router for navigation actions
export 'navigation/navigation.dart';

/// Context - AI Context Engine for automatic context injection
export 'context/context.dart';

/// Suggestions - AI Suggestions Card for contextual recommendations
export 'suggestions/suggestions.dart';

/// Workflow - Automated prescription workflow handling
export 'workflow/workflow.dart';

/// Polish - Production-ready utilities
export 'polish/polish.dart';

// ============================================================
// VERSION INFORMATION
// ============================================================

/// Astra Core version
const String astraCoreVersion = '1.0.0';

/// Astra Core build number
const int astraCoreBuildNumber = 1;
