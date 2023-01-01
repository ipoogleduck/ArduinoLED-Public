//
//  PresavedDrawings.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 5/9/21.
//

import Foundation

class StringInterpretationStruct {
    
    //Turns an encoded string back into an array of MatrixColor :)
    static func interpretStringToMatrixArray(_ string: String) -> [MatrixColor] {
        var matrix = Array(repeating: MatrixColor.black, count: 16*32)
        var i = 0
        while i < string.count {
            if string[i] == "f" {
                let color = MatrixColor(rawValue: string[i+1..<i+7])!
                matrix = Array(repeating: color, count: 16*32)
                i+=6
            } else if string[i] == "p" {
                let color = MatrixColor(rawValue: string[i+1..<i+7])!
                i+=7
                while string[i].isNumber && i < string.count {
                    let x = Int(string[i..<i+2])!
                    let y = Int(string[i+2..<i+4])!
                    let index = (y*32) + x
                    matrix[index] = color
                    i+=4
                }
            }
            i+=1
        }
        return matrix
    }
    
    //A set of presaved drawings saved at first launch
    static func getPreSavedDrawings() -> [[MatrixColor]] {
        let allPresaves = [
            //Poop
            "$bf000000p1515151307140715071707180719071308150817081908130915091709190913101410151017101810191014121512161217121812151316131713ep03010014021502160215031603170314041504160417041804140515051605170518051306140615061606170618061906120716072007120816082008120916092009111012101610201021101111121113111411151116111711181119112011211110121112121213121912201221122212101311131213131314131813191320132113221311141214131414141514161417141814191420142114e",
            //I love u text
            "$bf000000p15151501020202030204022202230224022502280229023002310201030203030304030803090310032303240329033003020403040804090423042404290430040205030507050805230524052905300502060306070623062406290630060207030723072407290730070208030823082408290830080209030923092409290930090210031023102410291030100211031123112411291130110212031223122412291230120113021303130413231324132513261327132813291330130114021403140414241425142614271428142914ep150000080209021002160217021802070311031503160317031803190306040704100411041204130414041504160417041804190420040605090510051105120513051405150516051705180519052005060608060906100611061206130614061506160617061806190620060607070708070907100711071207130714071507160717071807190720070708080809081008110812081308140815081608170818081908080909091009110912091309140915091609170918090910101011101210131014101510161017101011111112111311141115111611111212121312141215121213131314131314e",
            //Oliver fat
            "$bf000000p1515150302040205020602020306030204040405040305040502060306040605060606010702070607070701080708010907091709011006100710161018100111021103110411051106110711081117110012031204120912161217121812041317130314051417140215061516151815ep150000140015001600180021002300250027002800300031001401160118012301250127013001120214021502160218021902210224022702280230020903110309041004090510051105ep00151519052005210526052805200626063006310620072207240726072807300731071908230826082808300831082210211120122112221223122412251221132214e",
            //Cat face on pink bcknd
            "$bf150002p000000100020000901110119012101090212021802210208031303140315031603170322030804220408052205070623060707100711071207180719072007230707080908110813081708190821082308070910091109120918091909200923090710231007111311151117112311071214121612231208132213091410142114111512151315141515151615171518151915ep1515151001200110021102190220020903100311031203180319032003210309041004110412041504180419042004210409051005110512051405150516051805190520052105080609061006110612061306140615061606170618061906200621062206080709071307140715071607170721072207080814081508160822080809090913091409150916091709210922090810091010101110121013101410161017101810191020102110221009111011111112111411161118111911201121110812101211121212131215121712181219122012221209131013111312131313141315131613171318131913201321131114121413141414151416141714181419142014ep01010113041404160417041305170515100811221109122112ep0000151008120818082008e",
            //Time to poop
            "$bf000000p010101020905090211051103120412ep0015150303040305030603070309031203140317031803240305041204130414041704180419042304240425042804050509051105130515051705240527052905050609061106150617061806190624062806ep0301000908100811082308240825080909110923092509091010101110191023102410251009111311141115111811191120112311091213121512171218122012211223120913131314131513171318131913201321132313e",
            //Cat on gray
            "$bf010101p00000004030603110314031503160308040405070509051405150516050614071408141014111413141414151416141714181420142114231424142514ep0100000700120012012305150622061407091210121112181319131914ep15070009080809090910090810091010101110091110111111ep150200240007010801090110011101240105020602070208020902100211021202130223022402050307030803090310031203130323030504060407040904100411041204130414042204230405050605100511051205130517051805190520052105220505060606070608060906100611061206130614061606170618061906200621060607070708070907100711071207130715071607170718071907200707080808100811081208130814081508160817081808190820080709110912091309140915091609170918091909200912101310141015101610171018101910201021101211131114111511161117111811191120112111081212121312201221120813121321131214ep150100250013012501140225022403150424042107210821090710221008112211141215121612171218121912221209131313221309142214ep1500060805e",
            //Kitty Cat on dark orange
//            "$bf150100p0000001302140218021303150316031703090412041304140415041604170418042004080513051405160517051905080612061306140615061606170618062006080709081308140810091109120913091409150917091010111012101310151016101710ep1515151407150716071707150816081708160914101810ep01010114031803ep15070015051805ep1502003100031105110611081109111011111112111311141115111611171118111911201121112211241125112711e",
            //Kitty Cat on light orange
            "$bf150200p0000001302140218021303150316031703090412041304140415041604170418042004080513051405160517051905080612061306140615061606170618062006080709081308140810091109120913091409150917091010111012101310151016101710ep1515151407150716071707150816081708160914101810ep01010114031803ep15070015051805ep150100031105110611081109111011111112111311141115111611171118111911201121112211241125112711e",
            //Theo poopoo
            "$bf000000p0101010105020503050405050507051105120513050306070611061206130615061606170603070707080709071107150717070308070809081108120813081508160817081310141104120512061207120812091210121112121213121412151214131314ep010000260726092510ep0015001800240029001801230124012901180219022002210223022702280229022103270327042108ep00010122062407ep030100250223032403260321042204210527052006280619072907190828081809280918102710181126112711181219122012211224122512211322132313241321142214231424142514261420152115221523152415251526152715ep150002191120112111e",
            //Imposter
            "$f000000p01010116041704180409051005170518050806090608070808080908100811091109121012ep15000013021402150216021203130314031503160317031204130414041205130510061206130609071007120713070908130814081309140915091609141015101610ep01000011041105110611071008110812081808090910091109120917091809091010101110121013101710181010111111121113111411151116111711181111121212131214121512161217121812111312131313161317131813111412141314161417141814111512151315161517151815ep00001514051506150716071707ep00000114061906140718071907150816081708ep0001011504150516051905160617061806e"
        
        ]
        var saves: [[MatrixColor]] = []
        for save in allPresaves {
            saves.append(interpretStringToMatrixArray(save))
        }
        return saves
    }
}



//MARK: Startup animation
/*
 
 "$f000000p15000015081608ed50f000000p150000140815081608170815091609ed50f000000p150000150616061407150716071707140815081608170815091609ed50f000000p15000014051705130614061506160617061806130714071507160717071807130814081508160817081808140915091609170915101610ed50f000000p1500001305140517051805120613061406150616061706180619061207130714071507160717071807190712081308140815081608170818081908130914091509160917091809141015101610171015111611ed50f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed50f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed50f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed50f000000p150000120313031803190311041204130414041704180419042004100511051205130514051505160517051805190520052105100611061206130614061506160617061806190620062106100711071207130714071507160717071807190720072107100811081208130814081508160817081808190820082108110912091309140915091609170918091909200912101310141015101610171018101910131114111511161117111811141215121612171215131613ed50f000000p15000013041404170418041205130514051505160517051805190511061206130614061506160617061806190620061107120713071407150716071707180719072007110812081308140815081608170818081908200812091309140915091609170918091909131014101510161017101810141115111611171115121612ed50^"
 
 */