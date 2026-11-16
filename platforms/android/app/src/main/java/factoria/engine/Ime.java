// The engine's input method connection on Android (written by factoria export from platforms/android in the engine repo;
// do not edit it in an exported project, export again).
//
// A NativeActivity has no text editor, so a keyboard that composes (Japanese, Chinese, Korean, predictive words) has
// nothing to compose into. While a TextField has the focus the engine (engine/platform/src/ime_android.cpp) turns this
// class's view on: a 1x1 view that draws nothing, takes the focus and answers onCreateInputConnection. What the input
// method does on that connection goes to the engine, which decides (engine/platform/src/ime_ic.h, tested on every OS):
//   setComposingText -> the pre-edit string; commitText -> typed; finishComposingText -> the pre-edit string typed;
//   deleteSurroundingText -> Backspace / Delete; performEditorAction -> Enter; closeConnection -> the composition dropped.
// Nothing typed stays in the connection's text: the field has it, and an input method that could read it back would try
// to compose it again. Keys (hardware keys, and those an input method sends) go through the activity's input queue as
// before. With the view off it is not a text editor, so the keyboard sends keys, as it did before this class.
//
// The engine calls the public methods from its own thread; each one posts its work to the UI thread, where the input
// method calls the connection too. Every Java call into the engine carries the generation the connection was made for:
// the engine drops what an older connection says (a composition the UI already committed or cancelled).
package factoria.engine;

import android.app.Activity;
import android.content.Context;
import android.graphics.Matrix;
import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.text.Spanned;
import android.text.style.BackgroundColorSpan;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.CursorAnchorInfo;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;

public final class Ime {
    private static final String TAG = "factoria";
    private static final int SHOW_TRIES = 5;      // showSoftInput before the focus has reached the input method
    private static final long SHOW_RETRY_MS = 50;

    private Ime() {}

    // ---- the engine (engine/platform/src/ime_android.cpp registers these)
    private static native void nativeCompose(int generation, String text, int newCursorPosition, int[] clauses);
    private static native void nativeCommit(int generation, String text);
    private static native void nativeFinish(int generation);
    private static native void nativeDelete(int generation, int before, int after);
    private static native void nativeAction(int generation);
    private static native void nativeClose(int generation);

    private static ImeView view;  // UI thread only; made the first time the IME is turned on
    private static boolean failed;  // UI thread only: something threw, the IME stays off

    // ---- called by the engine, on its thread

    // A TextField has the focus (on) or none has. The connection made from now on carries `generation`.
    public static void setEnabled(final Activity activity, final boolean on, final int generation) {
        activity.runOnUiThread(() -> {
            try {
                ImeView v = on ? view(activity) : view;
                if (v == null) return;
                v.active = on && !failed;
                v.generation = generation;
                if (v.active && !v.hasFocus()) v.requestFocus();
                InputMethodManager imm = v.imm();
                if (imm != null) imm.restartInput(v);  // a new connection (on), or none (off): the old one is closed
            } catch (RuntimeException e) {
                fail(e);
            }
        });
    }

    // ime_cancel(): the composition in progress is dropped. A new connection with `generation` replaces the old one.
    public static void restart(final Activity activity, final int generation) {
        activity.runOnUiThread(() -> {
            try {
                ImeView v = view;
                if (v == null) return;
                v.generation = generation;
                InputMethodManager imm = v.imm();
                if (imm != null) imm.restartInput(v);
            } catch (RuntimeException e) {
                fail(e);
            }
        });
    }

    // The caret, in framebuffer pixels (fbWidth x fbHeight): where the input method puts its candidate window.
    public static void setCaret(final Activity activity, final float x, final float y, final float w, final float h,
                                final int fbWidth, final int fbHeight) {
        activity.runOnUiThread(() -> {
            try {
                ImeView v = view;
                if (v == null || !v.active) return;
                v.placeCaret(x, y, w, h, fbWidth, fbHeight);
            } catch (RuntimeException e) {
                fail(e);
            }
        });
    }

    // The on-screen keyboard, once this class is loaded: on the UI thread, in order with the calls above. While the IME is
    // on it is shown for this view; while it is off, as engine/platform/src/mobile_android.cpp does it (the activity's view
    // is no text editor, so showSoftInput may say no, and a forced toggle shows it then; the keyboard sends keys).
    public static void showKeyboard(final Activity activity, final boolean show) {
        activity.runOnUiThread(() -> {
            try {
                InputMethodManager imm = (InputMethodManager) activity.getSystemService(Context.INPUT_METHOD_SERVICE);
                View decor = activity.getWindow().getDecorView();
                if (imm == null || decor == null) return;
                ImeView v = view;
                if (!show)
                    imm.hideSoftInputFromWindow(decor.getWindowToken(), 0);
                else if (v != null && v.active)
                    v.show(imm, SHOW_TRIES);
                else
                    showWithoutConnection(imm, decor);
            } catch (RuntimeException e) {
                fail(e);
            }
        });
    }

    @SuppressWarnings("deprecation")  // SHOW_FORCED and toggleSoftInput: what a view that is no text editor still needs
    private static void showWithoutConnection(InputMethodManager imm, View decor) {
        if (!imm.showSoftInput(decor, InputMethodManager.SHOW_FORCED))
            imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
    }

    // ---- the UI thread

    private static ImeView view(Activity activity) {
        if (view == null && !failed) {
            ImeView v = new ImeView(activity);
            activity.addContentView(v, new ViewGroup.LayoutParams(1, 1));
            view = v;
        }
        return view;
    }

    // A failure turns the IME off for good: the keyboard goes back to sending keys, nothing is lost.
    private static void fail(RuntimeException e) {
        Log.w(TAG, "the input method connection failed; composition is off from now on", e);
        failed = true;
        ImeView v = view;
        if (v == null) return;
        v.active = false;
        try {
            InputMethodManager imm = v.imm();
            if (imm != null) imm.restartInput(v);
        } catch (RuntimeException ignored) {
            // nothing more to undo
        }
    }

    private static int[] clauses(CharSequence text) {
        if (!(text instanceof Spanned)) return new int[0];
        Spanned s = (Spanned) text;
        BackgroundColorSpan[] spans = s.getSpans(0, s.length(), BackgroundColorSpan.class);
        int[] out = new int[spans.length * 2];
        for (int i = 0; i < spans.length; ++i) {
            out[2 * i] = s.getSpanStart(spans[i]);
            out[2 * i + 1] = s.getSpanEnd(spans[i]);
        }
        return out;
    }

    private static final class ImeView extends View {
        boolean active;
        int generation;
        boolean monitor;  // the input method asked for every caret change (requestCursorUpdates)
        float caretHeight = 1;
        Connection connection;

        ImeView(Context context) {
            super(context);
            setFocusable(true);
            setFocusableInTouchMode(true);
            setWillNotDraw(true);
            setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);
        }

        InputMethodManager imm() {
            return (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        }

        @Override
        public boolean onCheckIsTextEditor() {
            return active;
        }

        @Override
        public InputConnection onCreateInputConnection(EditorInfo out) {
            if (!active) return null;
            out.inputType = InputType.TYPE_CLASS_TEXT;
            // Enter is a key (the field decides what it does); the keyboard never covers the game with its own editor.
            out.imeOptions = EditorInfo.IME_ACTION_NONE | EditorInfo.IME_FLAG_NO_ENTER_ACTION
                    | EditorInfo.IME_FLAG_NO_EXTRACT_UI | EditorInfo.IME_FLAG_NO_FULLSCREEN;
            out.initialSelStart = 0;
            out.initialSelEnd = 0;
            connection = new Connection(this, generation);
            return connection;
        }

        void show(InputMethodManager imm, int tries) {
            if (!active) return;
            if (!hasFocus()) requestFocus();
            if (imm.showSoftInput(this, 0) || tries <= 1) return;
            postDelayed(() -> {
                try {
                    InputMethodManager again = imm();
                    if (again != null) show(again, tries - 1);
                } catch (RuntimeException e) {
                    fail(e);
                }
            }, SHOW_RETRY_MS);
        }

        // The view moves to the caret (an input method that places its window by the view finds it there), and the
        // caret goes to the input method that monitors it.
        void placeCaret(float x, float y, float w, float h, int fbWidth, int fbHeight) {
            View root = getRootView();
            float scale = fbWidth > 0 && root != null && root.getWidth() > 0 ? (float) root.getWidth() / fbWidth : 1f;
            int[] parent = new int[2];
            if (getParent() instanceof View) ((View) getParent()).getLocationInWindow(parent);
            setTranslationX(x * scale - parent[0]);
            setTranslationY(y * scale - parent[1]);
            caretHeight = Math.max(1f, h * scale);
            cursorMoved();
        }

        void cursorMoved() {
            Connection c = connection;
            if (!monitor || c == null || !active) return;
            InputMethodManager imm = imm();
            if (imm == null) return;
            Editable e = c.getEditable();
            CursorAnchorInfo.Builder b = new CursorAnchorInfo.Builder();
            if (e != null) {
                b.setSelectionRange(Math.max(0, Selection.getSelectionStart(e)), Math.max(0, Selection.getSelectionEnd(e)));
                int start = BaseInputConnection.getComposingSpanStart(e), end = BaseInputConnection.getComposingSpanEnd(e);
                if (start >= 0 && end > start) b.setComposingText(start, e.subSequence(start, end));
            }
            int[] screen = new int[2];
            getLocationOnScreen(screen);
            Matrix m = new Matrix();
            m.setTranslate(screen[0], screen[1]);
            b.setMatrix(m);
            b.setInsertionMarkerLocation(0, 0, caretHeight, caretHeight, CursorAnchorInfo.FLAG_HAS_VISIBLE_REGION);
            imm.updateCursorAnchorInfo(this, b.build());
        }
    }

    private static final class Connection extends BaseInputConnection {
        private final ImeView owner;
        private final int generation;
        private boolean closed;

        Connection(ImeView owner, int generation) {
            super(owner, true);
            this.owner = owner;
            this.generation = generation;
        }

        // Only the pre-edit string lives in the editable (what the input method reads back while it composes).
        private void clear() {
            Editable e = getEditable();
            if (e == null) return;
            removeComposingSpans(e);
            e.clear();
        }

        @Override
        public boolean setComposingText(CharSequence text, int newCursorPosition) {
            if (closed) return false;
            super.setComposingText(text, newCursorPosition);
            nativeCompose(generation, text == null ? "" : text.toString(), newCursorPosition, clauses(text));
            owner.cursorMoved();
            return true;
        }

        @Override
        public boolean commitText(CharSequence text, int newCursorPosition) {
            if (closed) return false;
            nativeCommit(generation, text == null ? "" : text.toString());
            clear();
            owner.cursorMoved();
            return true;
        }

        @Override
        public boolean finishComposingText() {
            if (closed) return false;
            nativeFinish(generation);
            clear();
            return true;
        }

        // Nothing typed is here to recompose (it is in the field already): the region stays as it is.
        @Override
        public boolean setComposingRegion(int start, int end) {
            return !closed;
        }

        @Override
        public boolean deleteSurroundingText(int beforeLength, int afterLength) {
            if (closed) return false;
            nativeDelete(generation, Math.max(0, beforeLength), Math.max(0, afterLength));
            return true;
        }

        @Override
        public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
            return deleteSurroundingText(beforeLength, afterLength);
        }

        @Override
        public boolean performEditorAction(int editorAction) {
            if (closed) return false;
            nativeAction(generation);
            return true;
        }

        @Override
        public boolean requestCursorUpdates(int cursorUpdateMode) {
            if (closed) return false;
            owner.monitor = (cursorUpdateMode & InputConnection.CURSOR_UPDATE_MONITOR) != 0;
            if ((cursorUpdateMode & InputConnection.CURSOR_UPDATE_IMMEDIATE) != 0) owner.cursorMoved();
            return true;
        }

        // The connection is gone (the input restarted, the view lost the focus): its composition goes with it. Not
        // super's, which would finish (type) the composition.
        @Override
        public void closeConnection() {
            if (closed) return;
            closed = true;
            if (owner.connection == this) owner.connection = null;
            nativeClose(generation);
        }
    }
}
