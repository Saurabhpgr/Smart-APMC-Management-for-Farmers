import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DBService _dbService = DBService();

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String _error = '';

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String get error => _error;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await fetchAppUser();
      } else {
        _appUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchAppUser() async {
    if (_firebaseUser != null) {
      _appUser = await _dbService.getUser(_firebaseUser!.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      UserCredential? cred = await _authService.signInWithEmail(email, password);
      if (cred != null && cred.user != null) {
        AppUser? user = await _dbService.getUser(cred.user!.uid);
        if (user != null && user.role != 'admin' && user.status != 'approved') {
          _error = 'Your account is pending admin approval.';
          if (user.status == 'rejected') {
            _error = 'Your account registration was rejected.';
          }
          await _authService.signOut();
          _appUser = null;
          _firebaseUser = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'An error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(AppUser userData, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      UserCredential? cred = await _authService.registerWithEmail(userData.email, password);
      if (cred != null && cred.user != null) {
        AppUser newUser = AppUser(
          uid: cred.user!.uid,
          name: userData.name,
          email: userData.email,
          phone: userData.phone,
          role: userData.role,
          status: userData.role == 'admin' ? 'approved' : 'pending',
          createdAt: DateTime.now(),
          aadhaar: userData.aadhaar,
          village: userData.village,
          district: userData.district,
          state: userData.state,
          businessName: userData.businessName,
          licenseNumber: userData.licenseNumber,
        );
        await _dbService.createUser(newUser);
        
        if (newUser.role != 'admin') {
          _error = 'Registration successful! Please wait for admin approval.';
          await _authService.signOut();
          _appUser = null;
          _firebaseUser = null;
          _isLoading = false;
          notifyListeners();
          return false; // return false so the UI doesn't navigate to dashboard
        }

        _appUser = newUser;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'An error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      UserCredential? cred = await _authService.signInWithGoogle();
      if (cred != null && cred.user != null) {
        // Check if user exists in DB
        AppUser? existingUser = await _dbService.getUser(cred.user!.uid);
        if (existingUser != null) {
          if (existingUser.role != 'admin' && existingUser.status != 'approved') {
            _error = existingUser.status == 'rejected' 
                ? 'Your account registration was rejected.' 
                : 'Your account is pending admin approval.';
            await _authService.signOut();
            _appUser = null;
            _firebaseUser = null;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          _appUser = existingUser;
        } else {
          // New Google User - Needs Role Selection
          _appUser = null; 
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> completeGoogleSignIn(AppUser userData) async {
    if (_firebaseUser != null) {
        AppUser newUser = AppUser(
          uid: _firebaseUser!.uid,
          name: userData.name.isEmpty ? _firebaseUser!.displayName ?? '' : userData.name,
          email: _firebaseUser!.email ?? userData.email,
          phone: userData.phone,
          role: userData.role,
          status: userData.role == 'admin' ? 'approved' : 'pending',
          createdAt: DateTime.now(),
          aadhaar: userData.aadhaar,
          village: userData.village,
          district: userData.district,
          state: userData.state,
          businessName: userData.businessName,
          licenseNumber: userData.licenseNumber,
        );
        await _dbService.createUser(newUser);
        
        if (newUser.role != 'admin') {
          _error = 'Registration successful! Please wait for admin approval.';
          await _authService.signOut();
          _appUser = null;
          _firebaseUser = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        _appUser = newUser;
        notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
  }
}
