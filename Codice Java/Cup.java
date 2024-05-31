import javax.swing.*;
import java.awt.*;

public class Cup extends JPanel {
    private final int[] fillHeights = {0, 0, 0};
    private static final Color[] ING = {Color.BLUE, Color.ORANGE, Color.YELLOW};
    private int currentIng = 0;


    public Cup() {
        setPreferredSize(new Dimension(150, 225));
        setBackground(Color.white);
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.black);
        g.drawRect(0, 0, 150, 225);

        int currentY = 225;

        for (int i = 0; i < fillHeights.length; i++){
            g.setColor(ING[i]);
            g.fillRect(1, currentY - fillHeights[i], 149, fillHeights[i]);
            currentY -= fillHeights[i];
        }
    }

    public void nextIng() {
        currentIng = (currentIng + 1) % fillHeights.length;
    }

    public void pour() {
        if (sumHeights() + 2 <= 225) {
            fillHeights[currentIng] += 2;
            repaint();
        }
    }

    public int sumHeights() {
        int sum = 0;
        for (int i = 0; i < ING.length; i++) {
            sum += fillHeights[i];
        }
        return sum;
    }


    public void serve() {
        for (int i = 0; i < ING.length; i++) {
            fillHeights[i] = 0;
        }
        currentIng = 0;
        repaint();
    }

    public int[] getHeights() {
        return fillHeights;
    }
}
