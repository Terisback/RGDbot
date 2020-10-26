class Lev {
    static function main() {
        trace(demarauLev("man", "men"));
        trace(demarauLev("Mama", "Mom"));
        var s1 = "мама";
        trace(s1.toUpperCase(), s1);
    }

    static function demarauLev(s:String, t:String) {
        var bounds = {
            height: s.length + 1,
            widht: t.length + 1
        }
        
        var matrix:Array<Array<Float>> = [for(y in 0...bounds.height) [for (x in 0...bounds.widht) 0] ];

        for(height in 0...bounds.height)
            matrix[height][0] = height;

        for(widht in 0...bounds.widht)
            matrix[0][widht] = widht;

        for (height in 1...bounds.height) {
            for (widht in 1...bounds.widht) {
                var cost = (s.charAt(height-1) == t.charAt(widht-1)) ? 0 : 1;
                var insertion = matrix[height][widht-1] + 1;
                var deletion = matrix[height-1][widht] + 1;
                var substituion = matrix[height-1][widht-1] + cost;

                var distance = Math.min(insertion, Math.min(deletion, substituion));

                if (height > 1 && widht > 1 && s.charAt(height-1) == t.charAt(widht-2) && s.charAt(height-2) == t.charAt(widht-1)) {
                    distance = Math.min(distance, matrix[height-2][widht-2] + cost);
                }
                matrix[height][widht] = distance;
            }
        }

        return matrix[bounds.height - 1][bounds.widht - 1];

    }

}