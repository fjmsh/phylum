typedef NameConflictResolution = int;

const NameConflictResolution nameConflictError = 0;
const NameConflictResolution nameConflictEnsure = 1;
const NameConflictResolution nameConflictRename = 2;
const NameConflictResolution nameConflictOverwrite = 3;
const NameConflictResolution nameConflictDelete = 4;

class NameConflictException {
  const NameConflictException();
}
