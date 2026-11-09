/**
 * @file tacticalCoordinatesService.ts
 * @description Clean mathematical & coordinate transformation service for Stratbook and Tactical Radars.
 * Decouples DOM viewport measurements, zoom clamping, and vector geometry from React canvas rendering.
 */

export interface Point2D {
  readonly x: number;
  readonly y: number;
}

export interface ViewportTransform {
  readonly zoom: number;
  readonly panX: number;
  readonly panY: number;
}

export interface BoundingBox {
  readonly minX: number;
  readonly minY: number;
  readonly maxX: number;
  readonly maxY: number;
}

export class TacticalCoordinatesService {
  public static readonly LOGICAL_WIDTH = 840;
  public static readonly LOGICAL_HEIGHT = 480;
  public static readonly MIN_ZOOM = 0.5;
  public static readonly MAX_ZOOM = 3.0;

  /**
   * Clamps a zoom level between service bounds (0.5x - 3.0x).
   */
  public static clampZoom(zoom: number): number {
    return Math.max(this.MIN_ZOOM, Math.min(this.MAX_ZOOM, zoom));
  }

  /**
   * Converts screen/DOM pixel coordinates to logical radar coordinates (840x480).
   */
  public static toLogicalPoint(
    screenPoint: Point2D,
    canvasRect: DOMRect,
    transform: ViewportTransform,
  ): Point2D {
    const scaleX = canvasRect.width / this.LOGICAL_WIDTH;
    const scaleY = canvasRect.height / this.LOGICAL_HEIGHT;

    const canvasRelX = (screenPoint.x - canvasRect.left) / scaleX;
    const canvasRelY = (screenPoint.y - canvasRect.top) / scaleY;

    const logicalX = (canvasRelX - transform.panX) / transform.zoom;
    const logicalY = (canvasRelY - transform.panY) / transform.zoom;

    return {
      x: Math.round(logicalX * 10) / 10,
      y: Math.round(logicalY * 10) / 10,
    };
  }

  /**
   * Converts logical radar coordinates (840x480) back to screen/DOM pixel coordinates.
   */
  public static toScreenPoint(
    logicalPoint: Point2D,
    canvasRect: DOMRect,
    transform: ViewportTransform,
  ): Point2D {
    const scaleX = canvasRect.width / this.LOGICAL_WIDTH;
    const scaleY = canvasRect.height / this.LOGICAL_HEIGHT;

    const canvasRelX = logicalPoint.x * transform.zoom + transform.panX;
    const canvasRelY = logicalPoint.y * transform.zoom + transform.panY;

    return {
      x: canvasRect.left + canvasRelX * scaleX,
      y: canvasRect.top + canvasRelY * scaleY,
    };
  }

  /**
   * Checks whether a point is within standard logical radar boundaries.
   */
  public static isWithinBounds(point: Point2D): boolean {
    return (
      point.x >= 0 &&
      point.x <= this.LOGICAL_WIDTH &&
      point.y >= 0 &&
      point.y <= this.LOGICAL_HEIGHT
    );
  }

  /**
   * Calculates the Euclidean distance between two tactical points.
   */
  public static getEuclideanDistance(p1: Point2D, p2: Point2D): number {
    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Calculates the compass heading / angle in degrees between two tactical points.
   */
  public static getAngleDegrees(from: Point2D, to: Point2D): number {
    const dy = to.y - from.y;
    const dx = to.x - from.x;
    const rad = Math.atan2(dy, dx);
    const deg = (rad * 180) / Math.PI;
    return (deg + 360) % 360;
  }
}
